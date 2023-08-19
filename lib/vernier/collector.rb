# frozen_string_literal: true

require_relative "marker"

module Vernier
  class Collector
    def initialize(mode)
      @mode = mode
      @markers = []
    end

    ##
    # Get the current time.
    #
    # This method returns the current time from Process.clock_gettime in
    # integer nanoseconds.  It's the same time used by Vernier internals and
    # can be used to generate timestamps for custom markers.
    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    end

    def add_marker(name:, type: name.to_sym, start:, finish:, thread: Thread.current.native_thread_id, phase: Marker::Phase::INTERVAL, data: nil)
      @markers << [thread,
                   name,
                   type,
                   start,
                   finish,
                   phase,
                   data]
    end

    ##
    # Record an interval with a name.  Yields to a block and records the amount
    # of time spent in the block as an interval marker.
    def record_interval name
      start = current_time
      yield
      add_marker(
        name:,
        start:,
        finish: current_time,
        phase: Marker::Phase::INTERVAL,
        thread: Thread.current.native_thread_id
      )
    end

    def stop
      result = finish

      marker_strings = Marker.name_table

      markers = self.markers.map do |(tid, type, phase, ts, te)|
        name = marker_strings[type]
        sym = Marker::MARKER_SYMBOLS[type]
        [tid, name, sym, ts, te, phase]
      end

      markers.concat @markers

      result.instance_variable_set(:@markers, markers)

      result
    end
  end
end
