//
//  
//
//  Created by Jiang Bian on 01/29/2013.
//  Copyright (c) 2013 Jiang Bian. All rights reserved.
//


#include <glog/logging.h>
#include <gflags/gflags.h>
#include <armadillo>
#include <map>
#include <mutex>
#include <chrono>
#include <thread>
#include <iomanip>

#include <boost/iostreams/device/file.hpp>
#include <boost/iostreams/stream.hpp>
#include <boost/filesystem.hpp>

#include <deconvolvefilter/deconvolvefilter.hpp>

using namespace std;
using namespace arma;


DEFINE_string(i, "",
                 "the path to the input timesereis, e.g., -i=../data/whole_brain.timeseries.txt");
DEFINE_string(o, "",
                 "the path to save the solved timesereis, e.g., -o=../result/solved.whole_brain.timeseries.txt");
DEFINE_double(fo, 0.5,
                 "FO parameter to define the HRF function (default to 0.5) use with -hrf_d option");
DEFINE_int32(hrf_d, 6,
                 "HRF_d parameter to define the HRF function (default to 6) use with -fo option");
DEFINE_double(lr, 0.01,
                 "learning rate, e.g., -lr=0.01");
DEFINE_double(eps, 0.005,
                 "epsilon, stop criteria, the algorithm converges when error < eps e.g., -eps=0.005");
DEFINE_int32(thread, 8,
                 "number of concurrent threads, you should set this based on number of cores the machine has, e.g., quad-core machine with hyperthread enabled should set this to 8 (default) ");

static bool requiredStringFlag(const char* flagname, const std::string& value) {
   if(value.empty()){
        return false;
   }else{
    return true;
   }
}
static const bool i_flag = google::RegisterFlagValidator(&FLAGS_i, &requiredStringFlag);
static const bool o_flag = google::RegisterFlagValidator(&FLAGS_o, &requiredStringFlag);

std::mutex map_mutex;
std::map<int, std::string> ordered_timeseries;
//dlmwrite('whole_brain.timeseries.txt', whole_brain, 'delimiter', ' ','precision', 6)

void save(int i, const std::string& s){
    map_mutex.lock();
    ordered_timeseries[i] = s;
    map_mutex.unlock();
}

void draw_progress_bar(double percent) {
  std::cout << "\x1B[2K"; // Erase the entire current line.
  std::cout << "\x1B[0E"; // Move to the beginning of the current line.
  std::string progress;
  int len = 50;
  for (int i = 0; i < len; ++i) {
    if (i < static_cast<int>(len * percent)) {
      progress += "=";
    } else {
      progress += " ";
    }
  }
  
  std::cout << "\r" "[" << progress << "] ";
  std::cout.width( 3 );
  std::cout << (static_cast<int>(100 * percent)) << "%" << std::flush;
}

void deconvolvefilter(const std::string& datafile, const std::string& outputfile) { 

    using namespace utils;
    using namespace df;
    Timer timer;
    ThreadPool pool(FLAGS_thread);
    std::vector< std::future<void> > futures;    
    
   
    double FO = FLAGS_fo; //0.5;
    int HRF_d = FLAGS_hrf_d; // 6
    vec hrf = df::hrf(1/FO, HRF_d);

    double lr = FLAGS_lr; // 0.01
    double eps = FLAGS_eps; //0.005;

    int cnt = 0;
    //const std::string datafile = "../data/whole_brain.timeseries.txt";
    //const std::string outputfile = "../result/solved.whole_brain.timeseries.txt";

    LOG(INFO) << "processing " << datafile << "; result will be saved in " << outputfile;
    LOG(INFO) << "thread pool size: " << FLAGS_thread;
    LOG(INFO) << "parameters: FO = " << FO << "; HRF_d = " << HRF_d << "; lr = " << lr << "; eps = " << eps;

    if (!boost::filesystem::exists(datafile)) {
        LOG(ERROR) << datafile << " doesn't exist...";
    } else {
        boost::iostreams::stream<boost::iostreams::file_source> file(datafile.c_str());

        std::string line;
        
        int i = 0;
        LOG(INFO) << "ingest data from " << datafile;
        while (std::getline(file, line)) {
            i ++;
            arma::vec x(line);
            
            //LOG(INFO) << "at: " << i;
            
            if( arma::sum(x) == 0.0) {
                std::stringstream ss;
                ss << setprecision(6) << x.t();

                save(i, ss.str());
                continue;
            }

            double m = arma::mean(x);

            x = x - m;

            futures.push_back(
                pool.enqueue([i,x,hrf,lr,eps](void) -> void {
                    DeconvovleFilterTask task(x, hrf, lr, eps);
                    std::stringstream ss;
                    ss << setprecision(6) << task.run().t();
                    
                    save(i, ss.str());
                })
            );
        }
        cnt = i + 1;
        LOG(INFO) << cnt << " tasks have been scheduled...";
    }

    std::chrono::milliseconds dura( 10000 );
    int progress = static_cast<int>(ordered_timeseries.size());

    while(progress < cnt - 1) {
        progress = static_cast<int>(ordered_timeseries.size());
        draw_progress_bar(double(progress)/cnt);
        std::this_thread::sleep_for( dura );
    }

    // don't really need to wait, just good practice to ensure threads are cleaned out
    for(size_t i = 0;i<futures.size();++i){
        futures[i].wait();
    }

    boost::iostreams::stream<boost::iostreams::file_sink> outfile(outputfile.c_str());

    for(int i = 0; i < cnt; i++) {
        outfile << ordered_timeseries[i];
    }    

    outfile.flush();

    timer.report_elapsed();
}


int main(int argc, char **argv) {
    // Initialize Google's logging library.
    google::InitGoogleLogging("DeconvolveFilter");

    FLAGS_logtostderr = true;
    FLAGS_colorlogtostderr = true;

    google::SetVersionString(df::df_version_string());

    // The first arg is the usage message, also important for testing.
    std::string usage_message = "deconvolvefilter -i whole.brain.timeseries.txt -o solved.brain.timeseries\n";

    google::SetUsageMessage(usage_message.c_str());

    google::ParseCommandLineFlags(&argc, &argv, true);

    deconvolvefilter(FLAGS_i, FLAGS_o);

    google::ShutDownCommandLineFlags();

    return 0;

}
