ExUnit.start()

# Configure test coverage
if System.get_env("COVERAGE") == "true" do
  ExUnit.configure(exclude: [:skip_on_coverage])
else
  ExUnit.configure(exclude: [])
end

# Performance test configuration
ExUnit.configure(
  timeout: 60_000,  # 60 second timeout for performance tests
  capture_log: true,
  max_failures: :infinity
)
