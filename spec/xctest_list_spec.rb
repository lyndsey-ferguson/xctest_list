require_relative '../lib/xctest_list'

def mock_foreach(filepath_pattern, file_fixture)
  if 'xctestswift'.match?(filepath_pattern)
    demangled_output = `cat '#{file_fixture}' | grep -v \\\\-\\\\[ | cut -d' ' -f3 | xargs -s 131072 xcrun swift-demangle | cut -d' ' -f3 | grep -e '[\\.|_]'test`
    demangled_output_lines = demangled_output.split("\n")
    allow(File).to receive(:foreach).with(filepath_pattern) do |&block|
      block.call(demangled_output_lines.shift)
    end
  else
    allow(File).to receive(:foreach).with(filepath_pattern) do |&block|
      File.readlines(file_fixture).each do |line|
        block.call(line)
      end
    end
  end
end

describe XCTestList do
  describe 'mocked tests' do
    before(:each) do
      allow(XCTestList).to receive(:system).with(/nm -U '.*'/).and_return('')
      allow(XCTestList).to receive(:system).with(/nm -gU '.*'/).and_return('')
      allow(XCTestList).to receive(:system).with(/^((?!nm -).*)/).and_call_original
      allow(File).to receive(:foreach).and_call_original
      mock_foreach(/.*xctestobjc.*/, './spec/fixtures/nm_objc_output.txt')
      mock_foreach(/.*xctestswift.*/, './spec/fixtures/nm_swift_output.txt')
    end

    describe 'WHEN given a binary with only Swift tests' do
      it 'THEN it returns only swift tests' do
        allow(File).to receive(:foreach).with(/.*xctestobjc.*/).and_yield('')
        parsed_tests = XCTestList.tests('./spec/fixtures/xctest_list.xctest')
        expect(parsed_tests).to eq(['SwiftTestsUITests/testExample'])
      end
    end

    describe 'WHEN given a binary with Objective-C & Swift tests' do
      it 'THEN it returns Objective-C & Swift tests' do
        mock_foreach(/.*xctestobjc.*/, './spec/fixtures/nm_objc_swift_output.txt')
        mock_foreach(/.*xctestswift.*/, './spec/fixtures/nm_objc_swift_output.txt')

        parsed_tests = XCTestList.tests('./spec/fixtures/xctest_list.xctest')
        expect(parsed_tests).to eq(
          [
            'ObjcTests/testExample',
            'ObjcTests/testPerformanceExample',
            'SwiftTestsUITests/testExample'
          ]
        )
      end
    end

    describe 'WHEN given a binary with only Objective-C' do
      it 'THEN it returns Objective-C' do
        allow(File).to receive(:foreach).with(/.*xctestswift.*/).and_yield('')
        parsed_tests = XCTestList.tests('./spec/fixtures/xctest_list.xctest')
        expect(parsed_tests).to eq(
          [
            'GemaUITests/testExample'
          ]
        )
      end
    end

    describe 'WHEN given a new style binary with only Objective-C' do
      it 'THEN it returns Objective-C' do
        allow(File).to receive(:foreach).with(/.*xctestswift.*/).and_yield('')
        parsed_tests = XCTestList.tests('./spec/fixtures/new_xctest_list.xctest')
        expect(parsed_tests).to eq(
          [
            'GemaUITests/testExample'
          ]
        )
      end
    end

    describe 'WHEN given an invalid xctest bundle' do
      it 'THEN it raises the correct exception' do
        expect { XCTestList.tests('./spec/fixtures/corrupt.xctest') }.to (
          raise_error(Exception) do |error|
            expect(error.message).to match(%r{Missing xctest binary: '.*corrupt.xctest/Contents/MacOS/corrupt'})
          end
        )
      end
    end

    describe 'WHEN given an something that is not a xctest bundle' do
      it 'THEN it raises the correct exception' do
        expect { XCTestList.tests('./spec/fixtures') }.to (
          raise_error(Exception) do |error|
            expect(error.message).to match(/Invalid xctest bundle given: '.*fixtures'/)
          end
        )
      end
    end

    describe 'WHEN given an something does not exist' do
      it 'THEN it raises the correct exception' do
        expect { XCTestList.tests('./spec/fixtures/perfection.xctest') }.to (
          raise_error(Exception) do |error|
            expect(error.message).to match(%r{Cannot find xctest bundle at path: '.*fixtures/perfection.xctest'})
          end
        )
      end
    end
  end

  describe 'real tests' do
    it 'finds swift 3 tests' do
      parsed_tests = XCTestList.tests('./spec/fixtures/Swift3/AtomicBoyUITests.xctest')
      expect(parsed_tests).to eq(["AtomicBoyUITests/testExample2", "AtomicBoyUITests/testExample", "SwiftAtomicBoyUITests/testExample"])
    end

    it 'finds swift 4 tests' do
      parsed_tests = XCTestList.tests('./spec/fixtures/Swift4.2/AtomicBoyUITests.xctest')
      expect(parsed_tests).to eq(["AtomicBoyUITests/testExample2", "AtomicBoyUITests/testExample", "SwiftAtomicBoyUITests/testExample"])
    end
  end
end
