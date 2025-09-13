defmodule PhoenixFoundation.PerformanceIntegrationTest do
  @moduledoc """
  Integration tests that verify the entire performance optimization stack works together.
  """
  
  use ExUnit.Case, async: false
  
  alias UniversalCriticalPathTracer
  alias ParallelHealthOptimizer
  alias NetDataCacheOptimizer
  alias CriticalPathSmoother

  setup do
    # Ensure clean state for integration tests
    if Process.whereis(NetDataCacheOptimizer) do
      GenServer.stop(NetDataCacheOptimizer, :normal)
    end
    
    {:ok, _pid} = NetDataCacheOptimizer.start_link()
    NetDataCacheOptimizer.clear_cache()
    Process.delete(:optimizations_applied)
    
    :ok
  end

  describe "full optimization stack integration" do
    test "all optimization modules work together" do
      # Test the complete optimization workflow
      
      # 1. Critical Path Tracing with multiple optimizers
      trace_result = UniversalCriticalPathTracer.trace("Integration Test", [
        {:step, "Health Check", fn -> 
          result = ParallelHealthOptimizer.get_health_status_fast()
          assert is_map(result)
          {:ok, result}
        end},
        {:step, "Cache Operation", fn ->
          result = NetDataCacheOptimizer.get_cached_metrics()
          assert is_tuple(result)
          {:ok, result}
        end},
        {:parallel, "Parallel Optimizations", [
          fn -> ParallelHealthOptimizer.get_health_status_fast() end,
          fn -> NetDataCacheOptimizer.get_cached_load() end,
          fn -> NetDataCacheOptimizer.get_cached_memory() end
        ]}
      ])
      
      assert trace_result.name == "Integration Test"
      assert length(trace_result.steps) == 3
      assert trace_result.total_duration > 0
      
      # Verify each step completed successfully
      for step <- trace_result.steps do
        assert step.error == nil or is_nil(step.error)
        assert step.duration_us > 0
      end
    end

    test "optimization stack demonstrates performance improvements" do
      # Test that our optimizations actually improve performance
      
      # Baseline: Sequential operations
      baseline_start = System.monotonic_time(:microsecond)
      _result1 = ParallelHealthOptimizer.get_health_status_fast()
      _result2 = NetDataCacheOptimizer.get_cached_metrics()
      _result3 = NetDataCacheOptimizer.get_cached_load()
      baseline_duration = System.monotonic_time(:microsecond) - baseline_start
      
      # Optimized: Parallel + Cached operations
      optimized_start = System.monotonic_time(:microsecond)
      
      trace_result = UniversalCriticalPathTracer.trace("Optimized Operations", [
        {:parallel, "All Operations", [
          fn -> ParallelHealthOptimizer.get_health_status_fast() end,
          fn -> NetDataCacheOptimizer.get_cached_metrics() end,  # Should be cached now
          fn -> NetDataCacheOptimizer.get_cached_load() end
        ]}
      ])
      
      optimized_duration = System.monotonic_time(:microsecond) - optimized_start
      
      # Verify the optimized approach has performance benefits
      assert trace_result.total_duration < baseline_duration
      assert optimized_duration < baseline_duration
      
      # Should have completed the operations
      assert length(trace_result.steps) == 1
      parallel_step = List.first(trace_result.steps)
      assert parallel_step.name == "All Operations"
    end

    test "critical path smoother integrates with all modules" do
      # Verify that the smoother can work with our optimization modules
      output = ExUnit.CaptureIO.capture_io(fn ->
        # Run a smaller smoother iteration for testing
        original_limit = Application.get_env(:phoenix_foundation, :smoother_iteration_limit, 10)
        
        try do
          # Temporarily reduce iterations for faster test
          System.put_env("SMOOTHER_ITERATIONS", "3")
          
          result = CriticalPathSmoother.smooth_critical_paths()
          
          assert is_map(result)
          assert result.iteration <= 11  # Should complete within iteration limit
          assert is_list(result.bottlenecks)
          
        after
          System.delete_env("SMOOTHER_ITERATIONS")
        end
      end)
      
      # Verify smoother output contains expected optimization information
      assert String.contains?(output, "Critical Path Smoothing")
      assert String.contains?(output, "Optimization")
      assert String.contains?(output, "Performance Metrics")
    end

    test "error recovery across all modules" do
      # Test that errors in one module don't break the entire stack
      
      # Clear cache to ensure fresh state
      NetDataCacheOptimizer.clear_cache()
      
      # Run operations that might have errors but should recover gracefully
      trace_result = UniversalCriticalPathTracer.trace("Error Recovery Test", [
        {:step, "Health Check", fn -> ParallelHealthOptimizer.get_health_status_fast() end},
        {:step, "Cache with Potential Error", fn -> 
          case NetDataCacheOptimizer.get_cached_metrics() do
            {:ok, data, status} -> {:ok, {data, status}}
            {:error, reason} -> {:error, reason}  # Graceful error handling
          end
        end},
        {:step, "Recovery Operation", fn -> 
          # This should work regardless of previous errors
          {:ok, :recovered}
        end}
      ])
      
      assert trace_result.name == "Error Recovery Test"
      assert length(trace_result.steps) == 3
      
      # Last step should always succeed
      recovery_step = List.last(trace_result.steps)
      assert recovery_step.name == "Recovery Operation"
      assert recovery_step.error == nil
    end
  end

  describe "performance benchmarking integration" do
    test "can benchmark the entire optimization stack" do
      # Test that we can benchmark our optimization improvements
      
      results = UniversalCriticalPathTracer.compare_paths([
        {"Without Optimizations", [
          {:step, "Sequential Health", fn -> 
            # Simulate slower sequential approach
            :timer.sleep(10)
            {:ok, :health_checked}
          end},
          {:step, "No Cache", fn ->
            # Simulate uncached operation
            :timer.sleep(20)
            {:ok, :data_fetched}
          end}
        ]},
        {"With Optimizations", [
          {:step, "Parallel Health", fn -> ParallelHealthOptimizer.get_health_status_fast() end},
          {:step, "Cached Data", fn -> NetDataCacheOptimizer.get_cached_metrics() end}
        ]}
      ])
      
      assert length(results) == 2
      [optimized, unoptimized] = results
      
      # Optimized should be faster
      assert optimized.total_duration <= unoptimized.total_duration
    end
  end

  describe "memory and resource management" do
    test "optimization modules don't leak resources" do
      initial_processes = length(Process.list())
      
      # Run multiple optimization cycles
      for _i <- 1..5 do
        ParallelHealthOptimizer.get_health_status_fast()
        NetDataCacheOptimizer.get_cached_metrics()
        
        UniversalCriticalPathTracer.trace("Memory Test #{_i}", [
          {:step, "Operation", fn -> {:ok, :done} end}
        ])
      end
      
      # Force garbage collection
      :erlang.garbage_collect()
      :timer.sleep(100)
      
      final_processes = length(Process.list())
      
      # Process count should be stable (allowing some variance for test processes)
      assert abs(final_processes - initial_processes) < 10
    end
  end
end