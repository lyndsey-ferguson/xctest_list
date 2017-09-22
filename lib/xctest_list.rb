# NSString *swiftNmCmdline = @"nm -gU '%@' | cut -d' ' -f3 | xargs xcrun swift-demangle | cut -d' ' -f3 | grep -e '[\\.|_]'test";

require 'pathname'

class XCTestList
  def self.validate_bundle(xctest_bundle_path)
    raise "Cannot find xctest bundle at path '#{xctest_bundle_path}'" unless Dir.exist?(xctest_bundle_path)

    is_xctest_bundle = File.extname(xctest_bundle_path) == '.xctest'
    raise "Invalid xctest bundle given: '#{xctest_bundle_path}'" unless is_xctest_bundle
  end

  def self.binary_path(xctest_bundle_path)
    validate_bundle(xctest_bundle_path)

    xctest_binary_name = File.basename(xctest_bundle_path, '.*')
    xctest_binary_path = File.join(xctest_bundle_path, xctest_binary_name)
    unless File.exist?(xctest_binary_path)
      raise "Missing xctest binary: '#{xctest_binary_path}'"
    end
    xctest_binary_path
  end

  def self.tests(xctest_bundle_path)
    objc_symbols = 'nm -U '
    objc_symbols << "'#{binary_path(xctest_bundle_path)}'"

    tests = []
    `#{objc_symbols}`.each_line do |line|
      if / t -\[(?<testclass>\w+) (?<testmethod>test\w+)\]/ =~ line
        tests << "#{testclass}/#{testmethod}"
      end
    end
    tests
  end
end
