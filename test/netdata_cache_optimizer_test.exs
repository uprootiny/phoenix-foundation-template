defmodule NetDataCacheOptimizerTest do
  use ExUnit.Case, async: false  # Not async due to GenServer state
  
  alias NetDataCacheOptimizer

  setup do
    # Ensure the optimizer is started fresh for each test
    if Process.whereis(NetDataCacheOptimizer) do
      GenServer.stop(NetDataCacheOptimizer, :normal)
    end
    
    {:ok, _pid} = NetDataCacheOptimizer.start_link()
    NetDataCacheOptimizer.clear_cache()
    
    :ok
  end

  describe "caching functionality" do
    test "cache miss then hit cycle" do
      # First call should be a cache miss
      {:ok, _data, status1} = NetDataCacheOptimizer.get_cached_metrics()
      assert status1 == :fresh
      
      # Immediate second call should be a cache hit
      {:ok, _data, status2} = NetDataCacheOptimizer.get_cached_metrics()
      assert status2 == :cached
    end

    test "cache expiration" do
      # Get initial data (cache miss)
      {:ok, data1, :fresh} = NetDataCacheOptimizer.get_cached_metrics()
      
      # Should be cached
      {:ok, data2, :cached} = NetDataCacheOptimizer.get_cached_metrics()
      assert data1 == data2
      
      # Wait for cache expiration (TTL is 5 seconds)
      :timer.sleep(6000)
      
      # Should be fresh again after expiration
      {:ok, _data3, :fresh} = NetDataCacheOptimizer.get_cached_metrics()
    end

    test "individual cache methods work" do
      # Test load average caching
      {:hit, _load_data} = NetDataCacheOptimizer.get_cached_load()
      
      # Test memory info caching  
      {:hit, _memory_data} = NetDataCacheOptimizer.get_cached_memory()
    end

    test "clear cache functionality" do
      # Populate cache
      {:ok, _data, :fresh} = NetDataCacheOptimizer.get_cached_metrics()
      {:ok, _data, :cached} = NetDataCacheOptimizer.get_cached_metrics()
      
      # Clear cache
      :ok = NetDataCacheOptimizer.clear_cache()
      
      # Next call should be fresh
      {:ok, _data, :fresh} = NetDataCacheOptimizer.get_cached_metrics()
    end
  end

  describe "performance improvement" do
    test "demonstrates caching performance benefit" do
      # First call (cache miss) - should be slower
      start_time1 = System.monotonic_time(:microsecond)
      {:ok, _data, :fresh} = NetDataCacheOptimizer.get_cached_metrics()
      end_time1 = System.monotonic_time(:microsecond)
      fresh_duration = end_time1 - start_time1
      
      # Second call (cache hit) - should be much faster
      start_time2 = System.monotonic_time(:microsecond)
      {:ok, _data, :cached} = NetDataCacheOptimizer.get_cached_metrics()
      end_time2 = System.monotonic_time(:microsecond)
      cached_duration = end_time2 - start_time2
      
      # Cached should be significantly faster
      assert cached_duration < fresh_duration / 2
    end

    test "benchmark caching improvement runs" do
      output = ExUnit.CaptureIO.capture_io(fn ->
        NetDataCacheOptimizer.benchmark_caching_improvement()
      end)
      
      assert String.contains?(output, "NetData Direct API")
      assert String.contains?(output, "NetData Cached API")
    end
  end

  describe "error handling" do
    test "handles network errors gracefully" do
      # The cache optimizer should handle curl failures gracefully
      # and return appropriate error tuples
      result = NetDataCacheOptimizer.get_cached_metrics()
      
      case result do
        {:ok, _data, _status} -> :ok  # Success case
        {:error, _reason} -> :ok      # Expected error case
      end
    end
  end
end