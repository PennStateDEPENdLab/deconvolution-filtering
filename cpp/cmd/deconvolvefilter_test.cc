//
//  
//
//  Created by Jiang Bian on 01/29/2013.
//  Copyright (c) 2013 Jiang Bian. All rights reserved.
//


#include <glog/logging.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <gflags/gflags.h>
#include <deconvolvefilter/deconvolvefilter.hpp>
#include <armadillo>
#include <boost/iostreams/device/file.hpp>
#include <boost/iostreams/stream.hpp>
#include <boost/filesystem.hpp>

using namespace std;
using namespace arma;

mat get_timeseries(const string& filename) {
    
    mat matrix;
    // Catch nonexistent files by opening the stream ourselves.
    std::fstream stream;
    stream.open(filename.c_str(), std::fstream::in);


    if (!stream.is_open()) {

        std::stringstream ss;
        ss << "Cannot open file '" << filename << "'. ";
        throw runtime_error(ss.str());
    }

    arma::file_type loadType = arma::diskio::guess_file_type(stream);

    const bool success = matrix.load(stream, loadType);
    
    if (!success)
      {
            std::stringstream ss;
            ss << "Loading from '" << filename << "' failed.";
        throw runtime_error(ss.str());
      }
    return matrix;
}

std::mutex map_mutex;
std::map<int, std::string> ordered_timeseries;
//dlmwrite('whole_brain.timeseries.txt', whole_brain, 'delimiter', ' ','precision', 6)

void save(int i, const std::string& s){
    map_mutex.lock();
    ordered_timeseries[i] = s;
    map_mutex.unlock();
}

TEST(DeconvolveFilter, deconvolveSingleThreadTest) { 

    using namespace utils;
    using namespace df;
    Timer timer;
    ThreadPool pool(8);
    std::vector< std::future<void> > futures;    
    
   
    double FO = 0.5;
    int HRF_d = 6;
    vec hrf = df::hrf(1/FO, HRF_d);

    double lr = 0.01;
    double eps = 0.005;

    int cnt = 0;
    const std::string datafile = "../data/whole_brain.timeseries.txt";
    const std::string outputfile = "../result/solved.whole_brain.timeseries.txt";

    if (!boost::filesystem::exists(datafile)) {
        LOG(ERROR) << datafile << " doesn't exist...";
    } else {
        boost::iostreams::stream<boost::iostreams::file_source> file(datafile.c_str());

        std::string line;
        
        int i = 0;
        while (std::getline(file, line)) {
            i ++;
            arma::vec x(line);
            
            LOG(INFO) << "at: " << i;
            
            if( arma::sum(x) == 0.0) {
                save(i, line);
                continue;
            }

            double m = arma::mean(x);

            x = x - m;

            futures.push_back(
                pool.enqueue([i,x,&hrf,lr,eps](void) -> void {
                    //LOG(INFO) << x.n_elem;
                    DeconvovleFilterTask task(x, hrf, lr, eps);
                    std::stringstream ss;
                    task.run().save(ss);
                    
                    save(i, ss.str());
                })
            );          
        }
        cnt = i;
    }

    for(size_t i = 0;i<futures.size();++i){
        futures[i].wait();
    }

    boost::iostreams::stream<boost::iostreams::file_sink> outfile(outputfile.c_str());

    for(int i = 0; i < cnt; i++) {
        outfile << ordered_timeseries[i] << "\n";
    }    

    outfile.flush();

    timer.report_elapsed();

}


int main(int argc, char **argv) {
// Initialize Google's logging library.
    google::InitGoogleLogging("DeconvolveFilterTest");
    FLAGS_logtostderr = true;

    FLAGS_colorlogtostderr = true;
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
