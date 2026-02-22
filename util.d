module util;

// Returns a range over any linked-list-like thing.
// Just requires a pointer property for next.
// Optionally, an isNull property will be used to check for nullness.
auto linkedRange(T)(T* list) {
  static struct LinkedRange {
    T* front;

    static if (is(typeof(list.isNull))) {
      pragma(inline, true)
      static bool nullCheck(T* list) { return list.isNull; }
    }
    else {
      pragma(inline, true)
      static bool nullCheck(T* list) { return list == null; }
    }

    bool empty() {
      return nullCheck(front);
    }

    void popFront() {
      if (!nullCheck(front)) {
        front = front.next;
      }
    }
  }

  return LinkedRange(list);
}

// Returns a range over any graph-like thing that traverses it in pre-order.
// Just requires pointer properties for first, next, and parent.
// Optionally, an isNull property will be used to check for nullness.
auto preOrderRange(T)(T* graph) {
  import std.typecons : Tuple;

  static struct PreOrderRange {
    T* runner;
    int depth;

    static if (is(typeof(graph.isNull))) {
      pragma(inline, true)
      static bool nullCheck(T* graph) { return graph.isNull; }
    }
    else {
      pragma(inline, true)
      static bool nullCheck(T* graph) { return graph == null; }
    }

    Tuple!(T*, int) front() {
      return Tuple!(T*, int)(runner, depth);
    }

    bool empty() {
      return nullCheck(runner);
    }

    void popFront() {
      if (!nullCheck(runner)) {
        if (!nullCheck(runner.first)) {
          runner = runner.first;
          depth++;
        }
        else if (!nullCheck(runner.next)) {
          runner = runner.next;
        }
        else {
          while (true) {
            runner = runner.parent;
            depth--;
            if (nullCheck(runner)) return;
            if (!nullCheck(runner.next)) {
              runner = runner.next;
              break;
            }
          }
        }
      }
    }
  }

  return PreOrderRange(graph, 0);
}