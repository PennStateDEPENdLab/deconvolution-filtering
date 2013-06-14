// Jiang Bian. Copyright (C) 2013. MIT License.
#ifndef __DECONVOLVEFILTER_HPP__
#define __DECONVOLVEFILTER_HPP__

#include "config.h"
#include <exception>
#include <cstdlib>

#include "./version.hpp"
#include "./internal/utils.hpp"
#include "./internal/singleton.hpp"
#include "./internal/thread_pool.hpp"
#include "./internal/deconvolvefilter.hpp"

#define THROW_EXCEPTION( msg ) throw df::DFException( (msg), __FILE__, __LINE__ )

namespace df {

class DFException : public std::exception {
 public:
  DFException(const std::string& message, const char* filename, unsigned line ) :
    message_(message), filename_(std::string(filename)), line_(line) {}

  virtual ~DFException() throw() {}

  virtual const char* what() const throw() {
    std::stringstream ss;
    ss << "EXCEPTION: " << message_ << " in \"" << filename_ << "\",line:" <<
    line_;
    return ss.str().c_str();
  }

 protected:
  std::string message_;

  std::string filename_;

  unsigned line_;

};

}

#endif  // __DECONVOLVEFILTER_HPP__
