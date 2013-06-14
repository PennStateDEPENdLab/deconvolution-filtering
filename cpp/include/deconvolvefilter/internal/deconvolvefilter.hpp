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

namespace df {

	//Probability Density Function (PDF) of Gamma distribution 
	// x - Gamma-variate   (Gamma has range [0,Inf) ) 
	//  h - Shape parameter (h>0)
	// l - Scale parameter (l>0)
	arma::vec gPDF(arma::vec x, double h, double l){
		
		//LOG(INFO) << "h: " << h << "; l: " << l;
		//LOG(INFO) << "h * std::log(l): " << h * std::log(l);
		//LOG(INFO) << "arma::log(x) * (h - 1): " << arma::log(x) * (h - 1);
		//LOG(INFO) << "std::log(std::tgamma(h)): " << std::log(std::tgamma(h));
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

		LOG(INFO) << "l: " << l;

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

	

	class DeconvovleFilterTask {
	public:

		// data, FO, HRD_d, learning rate, and epsilon
		DeconvovleFilterTask(const arma::vec& data, const arma::vec& kernel, double lr, double eps) : data_(data), kernel_(kernel), lr_(lr), eps_(eps) {

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
		void run() {
			// %Calc time related to observations
			int N = data_.n_elem;

			//%Calc simulation steps related to simulation time
			int K = kernel_.n_elem;

			int A = K-1+N;

			double preverror = 1e9;
			double currerror = 0.0;

			LOG(INFO) << "N: " << N << "; K: " << K << "; A: " << A << "; prev_error: " << preverror;

			//LOG(INFO) << "max kernel: " << arma::max(kernel_) << "; pos: " << arma::find(kernel_ == arma::max(kernel_));

			arma::uvec max_hrf_id_adjust = arma::find(kernel_ == arma::max(kernel_)) - 1;
			int start = max_hrf_id_adjust.at(0);
			int end = N - 1;
			//LOG(INFO) << "start: " << start << "; end: " << end;
			
			//LOG(INFO) << range_uvec(start, end);

			arma::vec data_adjust = data_(range_uvec(start, end));

			LOG(INFO) << data_adjust;

			arma::vec encoding = data_adjust - arma::min(data_adjust);
			encoding = encoding / arma::max(encoding);

			LOG(INFO) << encoding;
			//%Construct activation vector
			// activation = zeros(A,1)+(2E-9).*rand(A,1)+(-1E-9);
  			arma::vec activation = arma::ones(A); //arma::randu<arma::vec>(A) * (2E-9) - (1E-9);
  			//LOG(INFO) << activation;

		}

	private:

		const arma::vec& data_;
		const arma::vec& kernel_;

		double lr_;
		double eps_;
	};

}

#endif  // __INTERNAL_DECONVOLVEFILTER_HPP__
