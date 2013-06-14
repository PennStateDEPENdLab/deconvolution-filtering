//
//  __SINGLETON_H__
//
//  Created by Jiang Bian on 1/18/13.
//  Copyright (c) 2013 Jiang Bian. All rights reserved.
//
#ifndef __SINGLETON_H__
#define __SINGLETON_H__

#include <boost/utility.hpp>
//#include <boost/thread/once.hpp>
#include <mutex>
#include <functional>
#include <memory>
#include <utility>

//using boost::once_flag;
//using boost::call_once;
using std::call_once;
using std::once_flag;


template <class T>
class Singleton : private boost::noncopyable {
  public:
    template <typename... Args>
    static T& getInstance(Args&&... args) {
      
      call_once(
        get_once_flag(),
        [] (Args&&... args) {
          instance_.reset(new T(std::forward<Args>(args)...));
        }, std::forward<Args>(args)...);
      /* c++11 standard does specific this syntax to be valid... but not supported by gcc-4.8 yet.
      Final Committee Draft, section 5.1.2.23:
      A capture followed by an ellipsis is a pack expansion (14.5.3). [ Example:

      template<class... Args> void f(Args... args) {
          auto lm = [&, args...] { return g(args...); }; lm();
      }
      — end example ]
      call_once(
        get_once_flag(),
        [&, args...] () {
          instance_.reset(new T(std::forward<Args>(args)...));
        });
      */
      return *instance_.get();
    }

  protected:
    explicit Singleton<T>() {}
    ~Singleton<T>() {}

  private:
    static std::unique_ptr<T> instance_;
    static once_flag& get_once_flag() {
      static once_flag once_;// = BOOST_ONCE_INIT;
      return once_;
    }
};

template<class T> std::unique_ptr<T> Singleton<T>::instance_ = nullptr;
// template<class T> once_flag Singleton<T>::once_ = BOOST_ONCE_INIT;

#endif
