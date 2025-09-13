defmodule ParallelHealthOptimizerTest do
  use ExUnit.Case, async: true
  
  alias ParallelHealthOptimizer

  describe "get_health_status_fast/0" do
    test "returns health status structure" do
      result = ParallelHealthOptimizer.get_health_status_fast()
      
      assert is_map(result)
      assert Map.has_key?(result, :results)
      assert Map.has_key?(result, :total_time_ms)
      assert Map.has_key?(result, :healthy_services)
      assert Map.has_key?(result, :total_services)
      assert Map.has_key?(result, :health_percentage)
      
      assert is_list(result.results)
      assert is_number(result.total_time_ms)
      assert is_integer(result.healthy_services)
      assert is_integer(result.total_services)
      assert is_number(result.health_percentage)
    end

    test "completes faster than sequential approach" do
      start_time = System.monotonic_time(:millisecond)
      result = ParallelHealthOptimizer.get_health_status_fast()
      end_time = System.monotonic_time(:millisecond)
      
      actual_time = end_time - start_time
      reported_time = result.total_time_ms
      
      # Should be significantly faster than sequential (which would be ~1000ms for 5 services)
      assert actual_time < 500  # Should complete in under 500ms
      assert reported_time < 500
    end

    test "validates all service results have required fields" do
      result = ParallelHealthOptimizer.get_health_status_fast()
      
      for service_result <- result.results do
        assert Map.has_key?(service_result, :service)
        assert Map.has_key?(service_result, :port)
        assert Map.has_key?(service_result, :healthy)
        assert Map.has_key?(service_result, :response_time_ms)
        assert Map.has_key?(service_result, :response_size)
        assert Map.has_key?(service_result, :status)
        
        assert is_binary(service_result.service)
        assert is_integer(service_result.port)
        assert is_boolean(service_result.healthy)
        assert is_number(service_result.response_time_ms)
        assert is_integer(service_result.response_size)
        assert service_result.status in [:ok, :error, :timeout, :exception]
      end
    end

    test "calculates health percentage correctly" do
      result = ParallelHealthOptimizer.get_health_status_fast()
      
      expected_percentage = result.healthy_services / result.total_services * 100
      assert_in_delta result.health_percentage, expected_percentage, 0.1
      
      assert result.health_percentage >= 0
      assert result.health_percentage <= 100
    end
  end

  describe "run_optimized_health_checks/0" do
    test "demonstrates performance comparison" do
      # This test captures output to verify the comparison runs
      output = ExUnit.CaptureIO.capture_io(fn ->
        ParallelHealthOptimizer.run_optimized_health_checks()
      end)
      
      assert String.contains?(output, "Optimized Parallel Health Checks")
      assert String.contains?(output, "Sequential Health Checks")
      assert String.contains?(output, "Parallel Health Checks")
    end
  end
end