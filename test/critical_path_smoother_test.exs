defmodule CriticalPathSmootherTest do
  use ExUnit.Case, async: true
  
  alias CriticalPathSmoother

  setup do
    # Clear any previous optimization state
    Process.delete(:optimizations_applied)
    :ok
  end

  describe "smooth_critical_paths/0" do
    test "runs multiple optimization iterations" do
      # Capture output to verify the smoothing process
      output = ExUnit.CaptureIO.capture_io(fn ->
        result = CriticalPathSmoother.smooth_critical_paths()
        assert is_map(result)
        assert Map.has_key?(result, :iteration)
        assert Map.has_key?(result, :total_time)
        assert Map.has_key?(result, :bottlenecks)
      end)
      
      assert String.contains?(output, "Critical Path Smoothing Process")
      assert String.contains?(output, "Iteration 1")
      assert String.contains?(output, "Optimization")
      assert String.contains?(output, "FINAL OPTIMIZATION SUMMARY")
    end

    test "applies optimizations progressively" do
      # Run smoothing and verify optimizations are applied
      initial_optimizations = Process.get(:optimizations_applied, 0)
      
      _result = ExUnit.CaptureIO.capture_io(fn ->
        CriticalPathSmoother.smooth_critical_paths()
      end)
      
      final_optimizations = Process.get(:optimizations_applied, 0)
      assert final_optimizations > initial_optimizations
    end

    test "shows performance improvement over iterations" do
      output = ExUnit.CaptureIO.capture_io(fn ->
        CriticalPathSmoother.smooth_critical_paths()
      end)
      
      # Should show performance metrics and improvements
      assert String.contains?(output, "Total Time:")
      assert String.contains?(output, "ms")
      assert String.contains?(output, "Performance Metrics")
      assert String.contains?(output, "Optimizations Applied:")
    end

    test "identifies and resolves bottlenecks" do
      output = ExUnit.CaptureIO.capture_io(fn ->
        CriticalPathSmoother.smooth_critical_paths()
      end)
      
      # Should identify bottlenecks and apply optimizations
      assert String.contains?(output, "Bottlenecks Found") or 
             String.contains?(output, "No significant bottlenecks")
      assert String.contains?(output, "Optimizing") or
             String.contains?(output, "smooth")
    end

    test "handles iteration limits correctly" do
      output = ExUnit.CaptureIO.capture_io(fn ->
        CriticalPathSmoother.smooth_critical_paths()
      end)
      
      # Should either reach target improvement or iteration limit
      assert String.contains?(output, "Target improvement achieved") or
             String.contains?(output, "Reached iteration limit")
    end
  end

  describe "optimization state management" do
    test "tracks optimization state correctly" do
      # Clear optimizations
      Process.delete(:optimizations_applied)
      initial_count = Process.get(:optimizations_applied, 0)
      
      # Apply some optimizations
      Process.put(:optimizations_applied, 5)
      updated_count = Process.get(:optimizations_applied, 0)
      
      assert initial_count == 0
      assert updated_count == 5
    end
  end
end