require_relative '../lib/xctest_list'

describe XCTestList do
  describe 'WHEN given a binary with only Swift tests' do
    before(:each) do
      nm_swift_output = File.open('./spec/fixtures/nm_swift_output.txt').read
      allow(XCTestList).to receive(:system).with(/nm -U '.*'/).and_return('')
      allow(XCTestList).to receive(:system).with(/nm -gU '.*'/).and_return(nm_swift_output)
      allow(XCTestList).to receive(:system).with(/^((?!nm -).*)/).and_call_original
    end

    it 'THEN it returns only swift tests' do
      parsed_tests = XCTestList.tests('./spec/fixtures/xctest_list.xctest')
      expect(parsed_tests).to eq(['SwiftTestsUITests/testExample'])
    end
  end

  describe 'WHEN given a binary with Objective-C & Swift tests' do
    before(:each) do
      nm_objc_output = File.open('./spec/fixtures/nm_objc_swift_output.txt').read
      nm_swift_output = File.open('./spec/fixtures/nm_swift_output.txt').read
      allow(XCTestList).to receive(:system).with(/nm -U '.*'/).and_return(nm_objc_output)
      allow(XCTestList).to receive(:system).with(/nm -gU '.*'/).and_return(nm_swift_output)
      allow(XCTestList).to receive(:system).with(/^((?!nm -).*)/).and_call_original
    end

    it 'THEN it returns Objective-C & Swift tests' do
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
    before(:each) do
      nm_objc_output = File.open('./spec/fixtures/nm_objc_output.txt').read
      allow(XCTestList).to receive(:system).with(/nm -U '.*'/).and_return(nm_objc_output)
      allow(XCTestList).to receive(:system).with(/nm -gU '.*'/).and_return('')
      allow(XCTestList).to receive(:system).with(/^((?!nm -).*)/).and_call_original
    end

    it 'THEN it returns Objective-C' do
      parsed_tests = XCTestList.tests('./spec/fixtures/xctest_list.xctest')
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
          expect(error.message).to match(%r{Missing xctest binary: '.*corrupt.xctest/corrupt'})
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
