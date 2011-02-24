source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"
gem 'nokogiri'
gem 'ms-fasta', ">=0.4.1"

dev_gems = {
    "spec-more" => ">= 0.0.4",
    "bundler" => "~> 1.0.0",
    "jeweler" => "~> 1.5.2",
    "rcov" => ">= 0",
}

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  dev_gems.each do |name,version_string|
    gem name, version_string
  end
end

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development_large do
  dev_gems.each do |name,version_string|
    gem name, version_string
  end
  gem "ms-testdata", ">= 0.1.1"
end
