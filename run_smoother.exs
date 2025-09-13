Code.compile_file("lib/universal_critical_path_tracer.ex")
Code.compile_file("lib/critical_path_smoother.ex")

# Capture and display the optimization process
IO.puts "\n🚀 Starting Critical Path Optimization Process..."
IO.puts "This will run multiple iterations to smooth out performance bottlenecks\n"

# Clear any previous optimization state
Process.delete(:optimizations_applied)

# Run the smoothing process
result = CriticalPathSmoother.smooth_critical_paths()

IO.puts "\n✨ Critical Path Smoothing Complete!"
IO.puts "Check the detailed output above for optimization insights."