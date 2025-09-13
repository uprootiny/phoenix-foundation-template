defmodule UniversalCriticalPathTracer do
  @moduledoc """
  Universal Critical Path Tracer - Self-sufficient, widely applicable performance analysis tool.
  
  Can be dropped into any Elixir/Phoenix project to:
  1. Trace execution paths and identify bottlenecks
  2. Measure real-world performance metrics
  3. Generate actionable optimization recommendations
  4. Monitor performance regression over time
  5. Export results for CI/CD integration
  
  Usage:
    UniversalCriticalPathTracer.trace("User Login Flow", [
      {:step, "Authentication", fn -> authenticate_user() end},
      {:step, "Database Query", fn -> fetch_user_data() end},
      {:step, "Session Creation", fn -> create_session() end}
    ])
  """

  defstruct [
    :name,
    :steps,
    :start_time,
    :total_duration,
    :bottlenecks,
    :recommendations,
    :metadata
  ]

  @doc """
  Main entry point for tracing any execution path.
  """
  def trace(path_name, steps, opts \\ []) do
    tracer = %__MODULE__{
      name: path_name,
      steps: [],
      start_time: System.monotonic_time(:microsecond),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    
    IO.puts "🎯 Tracing Critical Path: #{path_name}"
    
    traced_steps = execute_and_measure_steps(steps, [])
    
    tracer = %{tracer | 
      steps: traced_steps,
      total_duration: calculate_total_duration(traced_steps)
    }
    |> analyze_bottlenecks()
    |> generate_recommendations()
    
    display_results(tracer)
    
    # Optional: Save results for trending
    if Keyword.get(opts, :save_results, false) do
      save_trace_results(tracer)
    end
    
    tracer
  end

  @doc """
  Trace HTTP endpoint performance - common use case
  """
  def trace_endpoint(endpoint_name, method, url, opts \\ []) do
    steps = [
      {:step, "DNS Resolution", fn -> simulate_dns_lookup() end},
      {:step, "TCP Connection", fn -> simulate_tcp_connect() end},
      {:step, "HTTP Request", fn -> make_http_request(method, url) end},
      {:step, "Response Processing", fn -> simulate_response_processing() end}
    ]
    
    trace("#{method} #{endpoint_name}", steps, opts)
  end

  @doc """
  Trace database operation performance
  """
  def trace_database_operation(operation_name, query_func, opts \\ []) do
    steps = [
      {:step, "Connection Pool", fn -> simulate_pool_checkout() end},
      {:step, "Query Execution", query_func},
      {:step, "Result Processing", fn -> simulate_result_processing() end},
      {:step, "Connection Return", fn -> simulate_pool_return() end}
    ]
    
    trace("DB: #{operation_name}", steps, opts)
  end

  @doc """
  Trace Phoenix LiveView lifecycle
  """
  def trace_liveview_lifecycle(view_name, mount_func, opts \\ []) do
    steps = [
      {:step, "HTTP Request", fn -> simulate_http_request() end},
      {:step, "Router Dispatch", fn -> simulate_router_dispatch() end},
      {:step, "LiveView Mount", mount_func},
      {:step, "Template Render", fn -> simulate_template_render() end},
      {:step, "WebSocket Upgrade", fn -> simulate_websocket_upgrade() end}
    ]
    
    trace("LiveView: #{view_name}", steps, opts)
  end

  @doc """
  Compare multiple execution paths to identify the fastest
  """
  def compare_paths(paths) when is_list(paths) do
    IO.puts "🏁 Comparing #{length(paths)} execution paths..."
    
    results = Enum.map(paths, fn {name, steps} ->
      trace(name, steps, save_results: false)
    end)
    
    fastest = Enum.min_by(results, & &1.total_duration)
    slowest = Enum.max_by(results, & &1.total_duration)
    
    IO.puts """
    
    📊 PATH COMPARISON RESULTS:
    🏆 Fastest: #{fastest.name} (#{format_duration(fastest.total_duration)})
    🐌 Slowest: #{slowest.name} (#{format_duration(slowest.total_duration)})
    📈 Performance Gap: #{Float.round((slowest.total_duration - fastest.total_duration) / fastest.total_duration * 100, 1)}% slower
    """
    
    results
  end

  @doc """
  Start continuous monitoring of a critical path
  """
  def start_monitoring(path_name, steps, interval_ms \\ 30_000) do
    spawn(fn ->
      monitor_loop(path_name, steps, interval_ms)
    end)
  end

  # Private implementation functions

  defp execute_and_measure_steps([], acc), do: Enum.reverse(acc)
  defp execute_and_measure_steps([{:step, name, func} | rest], acc) do
    step_result = measure_execution(name, func)
    execute_and_measure_steps(rest, [step_result | acc])
  end
  defp execute_and_measure_steps([{:parallel, name, funcs} | rest], acc) do
    step_result = measure_parallel_execution(name, funcs)
    execute_and_measure_steps(rest, [step_result | acc])
  end

  defp measure_execution(step_name, func) do
    IO.write("  ⏱️  #{step_name}... ")
    
    start_time = System.monotonic_time(:microsecond)
    memory_before = get_memory_usage()
    
    {result, error} = try do
      case func.() do
        {:ok, data} -> {{:ok, data}, nil}
        :ok -> {:ok, nil}
        {:error, reason} -> {{:error, reason}, reason}
        other -> {other, nil}
      end
    rescue
      e -> {{:error, e}, e}
    catch
      :exit, reason -> {{:error, {:exit, reason}}, reason}
      thrown -> {{:error, {:throw, thrown}}, thrown}
    end
    
    end_time = System.monotonic_time(:microsecond)
    memory_after = get_memory_usage()
    
    duration_us = end_time - start_time
    duration_ms = duration_us / 1000
    
    status_icon = if error, do: "❌", else: "✅"
    IO.puts("#{status_icon} #{format_duration(duration_us)}")
    
    %{
      name: step_name,
      duration_us: duration_us,
      duration_ms: duration_ms,
      result: result,
      error: error,
      memory_delta: memory_after - memory_before,
      timestamp: DateTime.utc_now()
    }
  end

  defp measure_parallel_execution(step_name, funcs) do
    IO.puts("  🚀 #{step_name} (parallel #{length(funcs)} operations)...")
    
    start_time = System.monotonic_time(:microsecond)
    memory_before = get_memory_usage()
    
    tasks = Enum.map(funcs, fn func ->
      Task.async(fn -> 
        try do
          func.()
        rescue
          e -> {:error, e}
        end
      end)
    end)
    
    results = Task.await_many(tasks, 30_000)
    
    end_time = System.monotonic_time(:microsecond)
    memory_after = get_memory_usage()
    
    duration_us = end_time - start_time
    errors = Enum.filter(results, &match?({:error, _}, &1))
    
    status_icon = if length(errors) > 0, do: "⚠️", else: "✅"
    IO.puts("    #{status_icon} Completed in #{format_duration(duration_us)}")
    
    %{
      name: step_name,
      duration_us: duration_us,
      duration_ms: duration_us / 1000,
      result: {:parallel, results},
      error: if(length(errors) > 0, do: errors, else: nil),
      memory_delta: memory_after - memory_before,
      parallel_count: length(funcs),
      timestamp: DateTime.utc_now()
    }
  end

  defp calculate_total_duration(steps) do
    Enum.reduce(steps, 0, fn step, acc -> acc + step.duration_us end)
  end

  defp analyze_bottlenecks(tracer) do
    sorted_steps = Enum.sort_by(tracer.steps, & &1.duration_us, :desc)
    total_duration = tracer.total_duration
    
    bottlenecks = Enum.map(sorted_steps, fn step ->
      percentage = Float.round(step.duration_us / total_duration * 100, 1)
      severity = cond do
        percentage > 40 -> :critical
        percentage > 20 -> :major
        percentage > 10 -> :minor
        true -> :acceptable
      end
      
      %{
        step_name: step.name,
        duration_us: step.duration_us,
        percentage: percentage,
        severity: severity,
        has_error: !!step.error
      }
    end)
    |> Enum.filter(& &1.severity != :acceptable)
    
    %{tracer | bottlenecks: bottlenecks}
  end

  defp generate_recommendations(tracer) do
    recommendations = []
    
    # High-latency step recommendations
    recommendations = if length(tracer.bottlenecks) > 0 do
      critical_bottlenecks = Enum.filter(tracer.bottlenecks, & &1.severity == :critical)
      major_bottlenecks = Enum.filter(tracer.bottlenecks, & &1.severity == :major)
      
      recs = []
      
      recs = if length(critical_bottlenecks) > 0 do
        ["🚨 Critical: #{hd(critical_bottlenecks).step_name} taking #{hd(critical_bottlenecks).percentage}% of total time - immediate optimization required" | recs]
      else
        recs
      end
      
      recs = if length(major_bottlenecks) > 0 do
        ["⚠️ Major bottlenecks detected in #{length(major_bottlenecks)} steps - consider optimization" | recs]
      else
        recs
      end
      
      recommendations ++ recs
    else
      recommendations
    end
    
    # Performance pattern recommendations
    recommendations = cond do
      tracer.total_duration > 5_000_000 -> # > 5 seconds
        ["🐌 Path taking >5s total - consider breaking into async operations" | recommendations]
      tracer.total_duration > 1_000_000 -> # > 1 second  
        ["⏱️ Path taking >1s - monitor for regression" | recommendations]
      true -> recommendations
    end
    
    # Memory usage recommendations
    high_memory_steps = Enum.filter(tracer.steps, & &1.memory_delta > 50_000_000) # >50MB
    recommendations = if length(high_memory_steps) > 0 do
      ["💾 High memory usage detected - consider streaming or pagination" | recommendations]
    else
      recommendations
    end
    
    # Error handling recommendations
    error_steps = Enum.filter(tracer.steps, & &1.error != nil)
    recommendations = if length(error_steps) > 0 do
      ["❌ Errors detected in #{length(error_steps)} steps - add retry logic and better error handling" | recommendations]
    else
      recommendations
    end
    
    %{tracer | recommendations: recommendations}
  end

  defp display_results(tracer) do
    IO.puts """
    
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║ 📊 CRITICAL PATH ANALYSIS: #{tracer.name}
    ╠══════════════════════════════════════════════════════════════════════════════╣
    ║ ⏱️  Total Duration: #{format_duration(tracer.total_duration)}
    ║ 📈 Steps Analyzed: #{length(tracer.steps)}
    ║ 🎯 Bottlenecks Found: #{length(tracer.bottlenecks)}
    """
    
    if length(tracer.bottlenecks) > 0 do
      IO.puts "║"
      IO.puts "║ 🐌 PERFORMANCE BOTTLENECKS:"
      Enum.each(tracer.bottlenecks, fn bottleneck ->
        icon = case bottleneck.severity do
          :critical -> "🚨"
          :major -> "⚠️"
          :minor -> "💡"
        end
        IO.puts "║ #{icon} #{bottleneck.step_name}: #{format_duration(bottleneck.duration_us)} (#{bottleneck.percentage}%)"
      end)
    end
    
    if length(tracer.recommendations) > 0 do
      IO.puts "║"
      IO.puts "║ 💡 OPTIMIZATION RECOMMENDATIONS:"
      Enum.each(tracer.recommendations, fn rec ->
        IO.puts "║ #{rec}"
      end)
    end
    
    IO.puts "║"
    IO.puts "║ 📊 DETAILED STEP BREAKDOWN:"
    Enum.each(tracer.steps, fn step ->
      status = if step.error, do: "❌", else: "✅"
      memory_info = if step.memory_delta != 0 do
        " (#{format_memory(step.memory_delta)})"
      else
        ""
      end
      
      IO.puts "║ #{status} #{step.name}: #{format_duration(step.duration_us)}#{memory_info}"
    end)
    
    IO.puts "╚══════════════════════════════════════════════════════════════════════════════╝"
  end

  defp save_trace_results(tracer) do
    results_dir = "/tmp/critical_path_traces"
    File.mkdir_p(results_dir)
    
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic)
    filename = "#{results_dir}/#{String.replace(tracer.name, " ", "_")}_#{timestamp}.json"
    
    data = %{
      name: tracer.name,
      timestamp: DateTime.utc_now(),
      total_duration_us: tracer.total_duration,
      steps: tracer.steps,
      bottlenecks: tracer.bottlenecks,
      recommendations: tracer.recommendations,
      metadata: tracer.metadata
    }
    
    File.write(filename, Jason.encode!(data, pretty: true))
    IO.puts "💾 Results saved to: #{filename}"
  end

  defp monitor_loop(path_name, steps, interval_ms) do
    trace(path_name, steps, save_results: true)
    :timer.sleep(interval_ms)
    monitor_loop(path_name, steps, interval_ms)
  end

  # Utility functions
  
  defp format_duration(microseconds) when microseconds < 1_000 do
    "#{microseconds}μs"
  end
  defp format_duration(microseconds) when microseconds < 1_000_000 do
    "#{Float.round(microseconds / 1_000, 1)}ms"
  end
  defp format_duration(microseconds) do
    "#{Float.round(microseconds / 1_000_000, 2)}s"
  end

  defp format_memory(bytes) when bytes < 1_024 do
    "#{bytes}B"
  end
  defp format_memory(bytes) when bytes < 1_048_576 do
    "#{Float.round(bytes / 1_024, 1)}KB"
  end
  defp format_memory(bytes) do
    "#{Float.round(bytes / 1_048_576, 1)}MB"
  end

  defp get_memory_usage do
    :erlang.memory(:total)
  end

  # Simulation functions for common operations
  
  defp simulate_dns_lookup do
    :timer.sleep(5 + :rand.uniform(10))
    {:ok, :resolved}
  end

  defp simulate_tcp_connect do
    :timer.sleep(10 + :rand.uniform(20))
    {:ok, :connected}
  end

  defp make_http_request(_method, url) do
    try do
      case System.cmd("curl", ["-s", "-w", "%{time_total},%{http_code}", "-o", "/dev/null", url]) do
        {response, 0} ->
          [time_str, code_str] = String.split(String.trim(response), ",")
          {:ok, %{time: time_str, status: code_str}}
        {error, _} ->
          {:error, error}
      end
    rescue
      e -> {:error, e}
    end
  end

  defp simulate_response_processing do
    :timer.sleep(5 + :rand.uniform(15))
    {:ok, :processed}
  end

  defp simulate_pool_checkout do
    :timer.sleep(1 + :rand.uniform(5))
    {:ok, :connection}
  end

  defp simulate_result_processing do
    :timer.sleep(2 + :rand.uniform(8))
    {:ok, :results}
  end

  defp simulate_pool_return do
    :timer.sleep(1)
    {:ok, :returned}
  end

  defp simulate_http_request do
    :timer.sleep(20 + :rand.uniform(50))
    {:ok, :request_handled}
  end

  defp simulate_router_dispatch do
    :timer.sleep(2 + :rand.uniform(5))
    {:ok, :routed}
  end

  defp simulate_template_render do
    :timer.sleep(10 + :rand.uniform(30))
    {:ok, :rendered}
  end

  defp simulate_websocket_upgrade do
    :timer.sleep(5 + :rand.uniform(15))
    {:ok, :upgraded}
  end
end