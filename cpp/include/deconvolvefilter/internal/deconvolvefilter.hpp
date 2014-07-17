//
//  __INTERNAL_DECONVOLVEFILTER_HPP__
//
//  Created by Jiang Bian on 6/12/13.
//  Copyright (c) 2013 Jiang Bian. All rights reserved.
//
#ifndef __INTERNAL_DECONVOLVEFILTER_HPP__
#define __INTERNAL_DECONVOLVEFILTER_HPP__

#include <cmath>
#include <armadillo>
#include <boost/iostreams/device/file.hpp>
#include <boost/iostreams/stream.hpp>
#include <boost/filesystem.hpp>

namespace df {

	//Probability Density Function (PDF) of Gamma distribution 
	// x - Gamma-variate   (Gamma has range [0,Inf) ) 
	//  h - Shape parameter (h>0)
	// l - Scale parameter (l>0)
	arma::vec gPDF(arma::vec x, double h, double l){
		
		arma::vec r = arma::exp(h * std::log(l) + arma::log(x) * (h - 1) -  (x*l) - std::log(std::tgamma(h)));

		return r;
	}

	
	arma::vec range_vec(int start, int end) {

		arma::vec r = arma::zeros<arma::vec>(end - start + 1);

		for (int i = start; i < end + 1; i++) {
			//LOG(INFO) << i - start;
			r(i - start) = i;
		}

		return r;
	}

	arma::uvec range_uvec(int start, int end) {
		arma::uvec r = arma::zeros<arma::uvec>(end - start + 1);

		for (int i = start; i < end + 1; i++) {
			//LOG(INFO) << i - start;
			r(i - start) = i;
		}

		return r;
	}

	// this function takes a vector of neural event and hrf kernel function and convolves the neural events and HRF function neural events
	arma::vec convolve_anev_roi_hrf(const arma::vec& NEVgen, const arma::vec& kernel) {
		int Bn = NEVgen.n_elem;
		int Bk = kernel.n_elem;

		arma::vec BLDgen = arma::zeros(Bn+Bk-1);

		//LOG(INFO) << BLDgen.n_elem;

		for(int i = 0; i < Bn; i ++){
			BLDgen(range_uvec(i,i+Bk-1)) = NEVgen(i) * kernel + BLDgen(range_uvec(i,i+Bk-1));
			//LOG(INFO) << BLDgen(range_uvec(i,i+Bk-1));
		}

		arma::vec r = BLDgen(range_uvec(0,Bn - 1));
		return r;
	}


	//using namespace arma;
	/**
		%Build observation kernel
		KERobs = spm_advanced_hrf(1/FO,HRF_d); see spm_hrf
	**/
	arma::vec hrf(double RT, int HRF_d) {
		int fMRI_T = 16;

		// using default,HRF_d only affects the first parameter, this is not a exact mapping to the spm_hrf function
		// matlab array is 1 index, c is 0... use a dummy to match matlab function...
		arma::vec p = {0, 6, 16, 1, 1, 6, 0, 32};

		p(1) = HRF_d;

		// dt  = RT/fMRI_T;
		double dt  = RT / fMRI_T;

		// u   = [0:(p(7)/dt)] - p(6)/dt;
		int l = p(7)/dt;

		//LOG(INFO) << "l: " << l;

		arma::vec u = range_vec(0, l);
		
		u = u - p(6)/dt;

		
		//double h = p(1)/p(3);
		//LOG(INFO) << "p(1): " << p(1) << "; p(3): " << p(3) << "; h: " << h;

		arma::vec raw = gPDF(u, p(1)/p(3), dt/p(3)) - gPDF(u, p(2)/p(4), dt/p(4))/p(5);

		arma::uvec indices = range_uvec(0,int(p(7)/RT)) * fMRI_T; //[0:(p(7)/RT)]*fMRI_T + 1 c++ is zero based...

		
		arma::vec hrf = raw.elem(indices);

		double s = arma::sum(hrf);
		hrf = hrf/s;

		return hrf;
	}

	arma::vec activation_test_data() {
		boost::iostreams::stream<boost::iostreams::file_source> file("../data/activation.txt");

        std::string line;

        std::getline(file, line);

        //LOG(INFO) << line;

        arma::vec x(line);
        return x;
	}
	/*
	function y = sigmoid(x)
    	y=(1./(1+exp(-x)));
	end
	*/
	arma::vec sigmoid(const arma::vec& x) {
		return 1 / (1 + arma::exp(x * -1));
	}

	arma::vec dsigmoid(const arma::vec& x) {
		return (1 - sigmoid(x)) * sigmoid(x);
	}

	double sigmoid(double x) {
		return 1.0 / (1.0 + std::exp(x * -1));
	}

	double dsigmoid(double x) {
		return (1.0 - sigmoid(x)) * sigmoid(x);
	}

	arma::mat generate_feature(const arma::vec& encoding, int K) {

		int n = encoding.n_elem;
		arma::mat fmatrix = arma::zeros(n, K);

		//LOG(INFO) << "fmatrix: n_rows: " << fmatrix.n_rows << "; n_cols: " << fmatrix.n_cols;
		//LOG(INFO) << fmatrix;
		//fmatrix.col(0) = encoding;
		for (int i = 0; i < K; i ++){

			arma::vec fill_in = arma::zeros(n);
			fill_in(range_uvec(i, n -1)) = encoding(range_uvec(0, n - i -1));
			fmatrix.col(i) = fill_in;
			
		}
		return fmatrix;
	}

	class DeconvovleFilterTask {
	public:

		// data, FO, HRD_d, learning rate, and epsilon
		DeconvovleFilterTask(const arma::vec& data, const arma::vec& kernel, double lr, double eps, bool convolve = true) : data_(data), kernel_(kernel), lr_(lr), eps_(eps), convolve_(convolve) {

		}

		~DeconvovleFilterTask() {

		}

		/**
			%
			%-Description
			% This function deconvolves the BOLD signal using Bush 2011 method
			%
			%-Inputs
			% BLDobs (data) - observed BOLD signal
			% kernel - assumed kernel of the BOLD signal
			% nev_lr - learning rate for the assignment of neural events
			% epsilon - relative error change (termination condition)
			%
			%-Outputs
			% encoding - reconstructed neural events
		**/
		arma::vec run() {
			// %Calc time related to observations
			int N = data_.n_elem;

			//%Calc simulation steps related to simulation time
			int K = kernel_.n_elem;

			int A = K-1+N;

			double preverror = 1e9;
			double currerror = 0.0;

			//LOG(INFO) << "N: " << N << "; K: " << K << "; A: " << A << "; prev_error: " << preverror;

			arma::uvec max_hrf_id_adjust = arma::find(kernel_ == arma::max(kernel_)) - 1;
			int start = max_hrf_id_adjust.at(0);
			int end = N - 1;
			
			//LOG(INFO) << "start: " << start << "; end: " << end;

			arma::vec data_adjust = data_(range_uvec(start, end));


			arma::vec encoding = data_adjust - arma::min(data_adjust);
			encoding = encoding / arma::max(encoding);

			//%Construct activation vector
			// activation = zeros(A,1)+(2E-9).*rand(A,1)+(-1E-9);
  			arma::vec activation = arma::randu<arma::vec>(A) * (2E-9) - (1E-9); // test activation data (activation_test_data();)

  			arma::uvec activation_indices = range_uvec(K, (K-1 + data_adjust.n_elem)) - 1;
  			
  			activation(activation_indices) = arma::log(encoding/(1-encoding));

 			
  			while(std::abs(preverror - currerror) > eps_) {

  				//%Compute encoding vector
   				encoding = sigmoid(activation);


   				// %Construct feature space
    			arma::mat feature = generate_feature(encoding,K);

    			// %Generate virtual bold response    			
    			// ytilde = feature(K:size(feature,1),:)*kernel;
    			arma::uvec ytilde_indicies = range_uvec(K - 1, feature.n_rows - 1);

    			arma::vec ytilde =  feature.rows(ytilde_indicies) * kernel_;

    			//%Convert to percent signal change
    			double meanCurrent = arma::mean(ytilde);
    			arma::vec brf = (ytilde - meanCurrent)/meanCurrent;

    			//%Compute dEdbrf
    			arma::vec dEdbrf = brf - data_;
    			
    			
    			//%Compute dbrfdy
    			//%dbrfdy = numerical_dbrfdy(ytilde);

    			//%Compute dEdy
    			//%dEdy = dbrfdy%*%dEdbrf

    			arma::vec dEdy = dEdbrf;

    			/*
					% dEda = dEdf*dfde*deda
    				%      = (dEdf*dfde)*deda
    				%      = Dede*deda
    				// shouldn't just use the kerne_? why need to get identity matrix?
    			*/
    			arma::mat dEde = arma::eye<arma::mat>(K, K) * kernel_;


    			// back_error = [zeros(1,K-1),dEdy',zeros(1,K-1)];

    			arma::vec back_error = arma::zeros(dEdy.n_elem + 2 * (K-1));

    			arma::uvec dEdy_indicies = range_uvec(K-1,K-2+dEdy.n_elem);
    			
    			back_error(dEdy_indicies) = dEdy;
				
				//%Backpropagate Errors
    			arma::vec delta = arma::zeros(A);
    			for(int i = 0; i < A; i ++) {
    				double active = activation(i);

    				double deda = dsigmoid(active);

    				arma::vec dEda = dEde * deda;

    				arma::vec this_error = back_error(range_uvec(i, (i-1 + K)));
    				delta(i) = arma::sum(dEda%this_error);
    				
    			} 

    			// %Update estimate
    			activation = activation - delta * lr_;

    			// %Iterate Learning
    			preverror = currerror;
    			currerror = arma::sum(dEdbrf%dEdbrf);
	
  			}

            if (convolve){
                // %Convolve Solved NEV with the HRF Model
                arma::vec result = convolve_anev_roi_hrf(encoding, kernel_);

                // %Prune the data to the observed range
                result = result(range_uvec(K-1,result.n_elem-1));

                // %Normalize to percent signal change
                
                double m = arma::mean(result);
                result = (result - m) / m;
                return result;
            }else{
                return encoding;
            }
		}

	private:

		const arma::vec& data_;
		const arma::vec& kernel_;

		double lr_;
		double eps_;
        bool convolve = true;
	};

}

#endif  // __INTERNAL_DECONVOLVEFILTER_HPP__
