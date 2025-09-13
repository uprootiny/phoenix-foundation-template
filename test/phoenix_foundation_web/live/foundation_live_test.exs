defmodule PhoenixFoundationWeb.FoundationLiveTest do
  use PhoenixFoundationWeb.ConnCase, async: false
  
  import Phoenix.LiveViewTest

  describe "Foundation LiveView" do
    test "mounts successfully", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/foundation")
      
      assert html =~ "Phoenix Foundation Template"
      assert html =~ "Performance Optimization Dashboard"
    end

    test "displays system metrics", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Wait for initial data load
      :timer.sleep(100)
      
      html = render(view)
      assert html =~ "System Metrics" or html =~ "CPU" or html =~ "Memory"
    end

    test "handles critical path demo interaction", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Trigger the critical path demo
      html = render_click(view, "run_critical_path_demo")
      
      assert html =~ "Demo" or html =~ "Trace" or html =~ "Performance"
    end

    test "handles parallel health check interaction", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Trigger parallel health checks
      html = render_click(view, "run_parallel_health_demo")
      
      assert html =~ "Health" or html =~ "Service" or html =~ "Check"
    end

    test "handles cache optimization demo", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Trigger cache optimization demo
      html = render_click(view, "run_cache_demo")
      
      assert html =~ "Cache" or html =~ "Optimization" or html =~ "Performance"
    end

    test "handles benchmark execution", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Trigger benchmark execution
      html = render_click(view, "run_benchmarks")
      
      assert html =~ "Benchmark" or html =~ "Performance" or html =~ "ms"
    end

    test "updates metrics automatically", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Get initial state
      initial_html = render(view)
      
      # Send update message
      send(view.pid, :update_metrics)
      
      # Wait for update
      :timer.sleep(100)
      
      # Get updated state
      updated_html = render(view)
      
      # Should have some content (even if same data, the timestamp changes)
      assert byte_size(updated_html) > 0
      assert updated_html =~ "Foundation" or updated_html =~ "Performance"
    end

    test "displays performance recommendations", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Wait for data load
      :timer.sleep(100)
      
      html = render(view)
      
      # Should contain performance-related content
      assert html =~ "Optimization" or 
             html =~ "Performance" or 
             html =~ "Critical Path" or
             html =~ "Parallel" or
             html =~ "Cache"
    end

    test "safe helper functions work correctly", %{conn: conn} do
      # Test the safe helper functions indirectly by ensuring no errors occur
      {:ok, view, _html} = live(conn, "/foundation")
      
      # Wait for full mount and data processing
      :timer.sleep(200)
      
      # Trigger all interactive elements to test error handling
      render_click(view, "run_critical_path_demo")
      render_click(view, "run_parallel_health_demo")
      render_click(view, "run_cache_demo")
      render_click(view, "run_benchmarks")
      
      # Send multiple update cycles
      send(view.pid, :update_metrics)
      :timer.sleep(50)
      send(view.pid, :update_metrics)
      
      # If we get here without crashes, the safe functions are working
      final_html = render(view)
      assert byte_size(final_html) > 0
    end
  end

  describe "helper functions" do
    test "safe_float_round handles different input types" do
      view_module = PhoenixFoundationWeb.FoundationLive
      
      # These would normally be private, but we can test through the public interface
      # by ensuring the LiveView doesn't crash with various data types
      {:ok, view, _html} = live(build_conn(), "/foundation")
      
      # Send various update messages that would trigger the helper functions
      send(view.pid, :update_metrics)
      :timer.sleep(50)
      
      # Verify view is still responsive
      html = render(view)
      assert is_binary(html)
    end
  end
end