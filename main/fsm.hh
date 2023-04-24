#ifndef FSM_HH
#define FSM_HH

#include <vector>
#include <tuple>
#include <functional>

class callback {
    std::vector<std::function<void()> > _cbs;
public:
    void add(std::function<void()> cb) { _cbs.push_back(cb); }
    void operator()() { for (auto cb: _cbs) cb(); }
};

class fsm_base {
protected:
    fsm_base() { current = this; }

public:
    void inputs()  { _inputs(); }
    void outputs() { _outputs(); }
    virtual void update() = 0;
    void iteration() { inputs(); update(); outputs(); }

private:
    callback _inputs;
    callback _outputs;

private:
    template<class T> friend class input;
    template<class T> friend class output; 
    static fsm_base* current;

protected:
    template <class T> friend class input; 
    template <class T, int Ticks> friend class input_debounced; 
    template <class T> friend class output; 
    void registerInput(std::function<void()> cb) { _inputs.add(cb); }
    void registerOutput(std::function<void()> cb) { _outputs.add(cb); }
};

template <class T> class io_initializer {};
template<> struct io_initializer<bool> { static const bool value = false; };
template<> struct io_initializer<int> { static const int value = 0; };
template<> struct io_initializer<long> { static const long value = 0L; };
template<> struct io_initializer<long long> { static const long long value = 0LL; };
template<> struct io_initializer<unsigned> { static const unsigned value = 0; };
template<> struct io_initializer<unsigned long> { static const unsigned long value = 0UL; };
template<> struct io_initializer<unsigned long long> { static const unsigned long long value = 0ULL; };
template<> struct io_initializer<float> { static constexpr float value = .0f; };
template<> struct io_initializer<double> { static constexpr double value = .0; };

template <class T>
class input {
protected:
    T _prev;
    T _value;

    std::function<T()> _getter;

    input(T p, T v, std::function<T()> get) : _prev(p), _value(v), _getter(get) {}

public:
    template <class S> friend S value(const input<S>& in);
    template <class S> friend std::tuple<bool,S> changed(const input<S>& in);
    template <class S> friend bool raising(const input<S>& in);
    template <class S> friend bool falling(const input<S>& in);
    template <class S> friend std::tuple<bool,S> raising_value(const input<S>& in);
    template <class S> friend std::tuple<bool,S> falling_value(const input<S>& in);

    input(T v, std::function<T()> get) : _prev(v), _value(v), _getter(get) {
        fsm_base::current->registerInput([this](){ 
            _prev = _value;
            _value = _getter();
        });
    }

    input(std::function<T()> get) : input(io_initializer<T>::value, get) {}

    operator T() const { return _value; }
};

template <class T>
inline T value(const input<T>& in) { return in._value; }

template <class T>
inline auto changed(const input<T>& in) { return make_tuple(in._value != in._prev, in._value); }

template <class S>
inline bool raising(const input<S>& in) { return in._value > in._prev; }

template <class S>
inline bool falling(const input<bool>& in) { return in._value < in._prev; }

template <class S>
inline std::tuple<bool,S> raising_value(const input<S>& in) { return make_tuple(in._value > in._prev, in._value); }

template <class S>
inline std::tuple<bool,S> falling_value(const input<S>& in) { return make_tuple(in._value < in._prev, in._value); }


template <class T>
class output {
protected:
    T _value;

    std::function<void(const T&)> _setter;

public:
    template <class S> friend S value(const output<S>& out);

    output(T v, std::function<void(const T&)> put) : _value(v), _setter(put) {
        fsm_base::current->registerOutput([this](){ _setter(_value); });
    }

    output(std::function<void(const T&)> put) : output(io_initializer<T>::value, put) {}

    output() : _value(io_initializer<T>::value), _setter([](const T&){}) {}

    output(const output<T>&) = default;

    output<T>& operator= (T v) { _value = v; return *this; }
    output<T>& operator= (const output<T>& v) { _value = v._value; return *this; }
    operator T() const { return _value; }
};

template <class T>
inline T value(const output<T>& out) { return out._value; }

#ifdef INC_FREERTOS_H // debouncing is FreeRTOS specific
# include <freertos/task.h>

template <class T, int Ticks>
class input_debounced: public input<T> {
    typedef input<T> base;
    TickType_t _last_change;

public:
    input_debounced(T v, std::function<T()> get) : base(v, v, get), _last_change(xTaskGetTickCount()) {
        fsm_base::current->registerInput([this](){ 
            base::_prev = base::_value;
            T v = base::_getter();
            TickType_t ts = xTaskGetTickCount();
            if (v != base::_value && (ts - _last_change) > Ticks) {
                base::_value = v;
                _last_change = ts;
            }
        });
    }

    input_debounced(std::function<T()> get) : input_debounced(io_initializer<T>::value, get) {}
};

#include <driver/gpio.h>

enum gpio_input_active_t {
    GPIO_INPUT_ACTIVE_HIGH,
    GPIO_INPUT_ACTIVE_LOW
};

template<int DebounceTicks>
class gpio_input_debounced: public input_debounced<bool,DebounceTicks> {
    typedef input_debounced<bool, DebounceTicks> base;
public:
    gpio_input_debounced(gpio_num_t pin, bool v, std::function<void(bool)> fn) 
        : base(v, [pin, v, fn](){ bool ret = gpio_get_level(pin); fn(v); return ret; }) 
    {
        gpio_set_direction(pin, GPIO_MODE_INPUT);
        gpio_set_pull_mode(pin, GPIO_PULLDOWN_ONLY);
    }

    gpio_input_debounced(gpio_num_t pin, bool v) : gpio_input_debounced(pin, v, [](bool){}) {}

    gpio_input_debounced(gpio_num_t pin) : gpio_input_debounced(pin, false, [](bool){}) {}
};

typedef gpio_input_debounced<10> gpio_input;

class gpio_output: public output<bool> {
    typedef output<bool> base;
public:
    gpio_output(gpio_num_t pin) : base(false,[pin](bool v){ gpio_set_level(pin, v); }) 
    {
        gpio_set_direction(pin, GPIO_MODE_OUTPUT);
        gpio_set_pull_mode(pin, GPIO_FLOATING);
    }

    gpio_output& operator= (bool v) { base::_value = v; return *this; }
    gpio_output& operator= (const gpio_output& v) { base::_value = v._value; return *this; }
    operator bool() { return base::_value; }

};

#endif


template <class State, class T>
class fsm : public fsm_base {
protected:
    typedef fsm<State,T> fsm_type;

    typedef struct {
        State from;
        std::function<bool()> guard;
        State to;
        std::function<void()> output;
    } transition;

    std::vector<transition> tt;
    State current;

public:
    fsm(std::initializer_list<transition> transitionTable): tt{transitionTable} { 
        current = tt[0].from; 
    }

    void update() {
        for (auto& t: tt) { // naïve, should be smarter
            if (current == t.from && t.guard()) {
                current = t.to;
                t.output();
                break;
            }
        }
    }
};

// FSM synchronous composition
class fsm_composite: public fsm_base {
    std::vector<std::reference_wrapper<fsm_base>> fsms;
    fsm_composite(const fsm_composite&) = delete;
    fsm_composite(fsm_composite&&) = delete;

public:
    fsm_composite(std::initializer_list<std::reference_wrapper<fsm_base>> list): fsms(list) {
        registerInput([this](){ for (auto f: fsms) f.get().inputs(); });
        registerOutput([this](){ for (auto f: fsms) f.get().outputs(); });
    }

    void update() { for (auto& f: fsms) f.get().update(); }
};

#endif
