defmodule UniversalCriticalPathTracerTest do
  use ExUnit.Case, async: true
  
  alias UniversalCriticalPathTracer

  describe "trace/2" do
    test "traces simple sequential operations" do
      result = UniversalCriticalPathTracer.trace("Test Operation", [
        {:step, "Step 1", fn -> :timer.sleep(10); {:ok, :step1_complete} end},
        {:step, "Step 2", fn -> :timer.sleep(5); {:ok, :step2_complete} end}
      ])
      
      assert result.name == "Test Operation"
      assert length(result.steps) == 2
      assert result.total_duration > 0
      
      [step1, step2] = result.steps
      assert step1.name == "Step 1"
      assert step1.duration_us >= 10_000  # At least 10ms in microseconds
      assert step2.name == "Step 2"
      assert step2.duration_us >= 5_000   # At least 5ms in microseconds
    end

    test "traces parallel operations" do
      result = UniversalCriticalPathTracer.trace("Parallel Test", [
        {:parallel, "Parallel Tasks", [
          fn -> :timer.sleep(20); {:ok, :task1} end,
          fn -> :timer.sleep(15); {:ok, :task2} end,
          fn -> :timer.sleep(10); {:ok, :task3} end
        ]}
      ])
      
      assert result.name == "Parallel Test"
      assert length(result.steps) == 1
      
      [parallel_step] = result.steps
      assert parallel_step.name == "Parallel Tasks"
      # Parallel execution should take about as long as the longest task (20ms)
      assert parallel_step.duration_us >= 20_000
      assert parallel_step.duration_us < 50_000  # Much less than sequential (45ms)
    end

    test "handles errors gracefully" do
      result = UniversalCriticalPathTracer.trace("Error Test", [
        {:step, "Good Step", fn -> {:ok, :success} end},
        {:step, "Bad Step", fn -> raise "Test error" end},
        {:step, "Recovery Step", fn -> {:ok, :recovered} end}
      ])
      
      assert result.name == "Error Test"
      assert length(result.steps) == 3
      
      [good, bad, recovery] = result.steps
      assert good.error == nil
      assert bad.error != nil
      assert is_binary(bad.error) or is_struct(bad.error)
      error_text = if is_binary(bad.error), do: bad.error, else: Exception.message(bad.error)
      assert String.contains?(error_text, "Test error")
      assert recovery.error == nil
    end

    test "identifies bottlenecks correctly" do
      result = UniversalCriticalPathTracer.trace("Bottleneck Test", [
        {:step, "Fast Step", fn -> :timer.sleep(1); {:ok, :fast} end},
        {:step, "Slow Step", fn -> :timer.sleep(50); {:ok, :slow} end},
        {:step, "Medium Step", fn -> :timer.sleep(10); {:ok, :medium} end}
      ])
      
      assert length(result.bottlenecks) > 0
      
      # Should identify bottlenecks (may be major or critical depending on thresholds)
      assert length(result.bottlenecks) > 0
      
      # Find the slow step bottleneck
      slow_bottleneck = Enum.find(result.bottlenecks, & &1.step_name == "Slow Step")
      assert slow_bottleneck != nil
      assert slow_bottleneck.percentage > 40  # Should be significant percentage of total time
    end
  end

  describe "compare_paths/1" do
    test "compares multiple execution paths" do
      paths = [
        {"Fast Path", [
          {:step, "Quick Step", fn -> :timer.sleep(5); {:ok, :done} end}
        ]},
        {"Slow Path", [
          {:step, "Slow Step", fn -> :timer.sleep(25); {:ok, :done} end}
        ]}
      ]
      
      result = UniversalCriticalPathTracer.compare_paths(paths)
      
      assert is_list(result)
      assert length(result) == 2
      
      # Results should be sorted by performance (fastest first)
      [fast_result, slow_result] = result
      assert fast_result.total_duration < slow_result.total_duration
    end
  end

  describe "format_duration/1" do
    test "formats microseconds correctly" do
      assert UniversalCriticalPathTracer.format_duration(500) == "500μs"
      assert UniversalCriticalPathTracer.format_duration(1500) == "1.5ms"
      assert UniversalCriticalPathTracer.format_duration(1_500_000) == "1.5s"
    end
  end

  describe "memory tracking" do
    test "tracks memory usage during operations" do
      result = UniversalCriticalPathTracer.trace("Memory Test", [
        {:step, "Memory Operation", fn -> 
          # Create some data to increase memory usage
          _data = Enum.map(1..1000, &(&1 * &1))
          {:ok, :memory_used}
        end}
      ])
      
      [step] = result.steps
      assert is_integer(step.memory_delta)
    end
  end
end