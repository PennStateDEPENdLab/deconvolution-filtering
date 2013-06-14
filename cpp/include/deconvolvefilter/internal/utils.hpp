//
//  __UTILS_H__
//
//  Created by Jiang Bian on 5/19/13.
//  Copyright (c) 2013 Jiang Bian. All rights reserved.
//
#ifndef __UTILS_H__
#define __UTILS_H__

#include <chrono>
#include <memory>
#include <glog/logging.h>


namespace utils {

	typedef std::chrono::high_resolution_clock clock;
	typedef std::chrono::milliseconds milliseconds;

	class Timer {
	public:
		Timer() {
            start_ = clock::now();
        }
		~Timer() {

        }

		int elapsed() {
            clock::time_point current = clock::now();
            milliseconds total_ms = std::chrono::duration_cast<milliseconds>(current - start_);

            return total_ms.count();
        }

		void report_elapsed() {
            int ms = elapsed();
            LOG(INFO) << float(ms)/1000/60 << " mins; " << ms << " ms has elapsed...";
        }

	private:
		clock::time_point start_;
	};
	
} // namespace utils

#endif