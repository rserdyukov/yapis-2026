class Counter
  var n: U32 = 0
  new create() => None
  fun ref inc() => n = n + 1
  fun box read(): U32 => n

actor Main
  new create(env: Env) =>
    let writable: Counter ref = Counter
    let view: Counter box = writable
    writable.inc()
    env.out.print(view.read().string())
    // view.inc()  // rejected: a box cannot call a ref method
    let frozen: Counter val = recover val Counter end
    env.out.print(frozen.read().string())
    // frozen.inc()  // rejected: val provides no mutation authority
    let isolated: Counter iso = recover iso Counter end
    let received: Counter iso = consume isolated
    received.inc()
    env.out.print(received.read().string())
    // isolated.read()  // rejected: isolated was consumed
