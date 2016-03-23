require 'spec_helper'

RSpec::Matchers.define :be_a_config_key_entry do
  match do |actual|
    actual.is_a? AppConfigRails::ConfigEntry
  end

  failure_message do |actual|
    "expected #{actual} to be a AppConfigRails::KeyEntry"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} to not be a AppConfigRails::KeyEntry"
  end
end

RSpec::Matchers.define :have_config_key_props do |env, domain, key, value|
  match do |actual|
    actual.env    == env &&
    actual.domain == domain &&
    actual.key    == key &&
    actual.value  == value
  end

  diffable
end

RSpec.describe AppConfigRails::Parser do
  describe '#parse' do
    let(:parser) { described_class.new }
    let(:result) { parser.parse(cfg_yml) }

    context 'with single key config' do
      let(:cfg_yml) do
        %Q{
          "test.hk.service_one.config_one": value_one
        }
      end

      it 'returns an array with one entry' do
        expect(result.count).to eq(1)
      end

      it 'returns a KeyEntry instance' do
        expect(result[0]).to be_a_config_key_entry
      end

      it 'has the correct values in the KeyEntry' do
        expect(result[0]).to have_config_key_props('test', :any, 'hk.service_one.config_one', 'value_one')
      end
    end

    context 'with multiple key config' do
      let(:cfg_yml) do
        %Q{
          "test.hk.service_one.config_one": value_one
          "prod.us.service_two": value_two
        }
      end

      it 'returns an array with two entry' do
        expect(result.count).to eq(2)
      end

      it 'returns two KeyEntry instances' do
        result.each do |k|
          expect(k).to be_a_config_key_entry
        end
      end

      it 'has the correct values in the KeyEntry' do
        expect(result[0]).to have_config_key_props('test', :any, 'hk.service_one.config_one', 'value_one')
        expect(result[1]).to have_config_key_props('prod', :any, 'us.service_two', 'value_two')
      end
    end

    context 'with single complex key config' do
      let(:cfg_yml) do
        %Q{
          "test.hk":
            "service_one.config_one": value_one
        }
      end

      it 'returns an array with one entry' do
        expect(result.count).to eq(1)
      end

      it 'returns a KeyEntry instance' do
        expect(result[0]).to be_a_config_key_entry
      end

      it 'has the correct values in the KeyEntry' do
        expect(result[0]).to have_config_key_props('test', :any, 'hk.service_one.config_one', 'value_one')
      end
    end

    context 'with nested complex key config' do
      let(:cfg_yml) do
        %Q{
          "test.hk":
            "service_one.config_one":
              part_one: value_one
              part_two: value_two
        }
      end

      it 'returns an array with two entry' do
        expect(result.count).to eq(2)
      end

      it 'returns only KeyEntry instance' do
        result.each do |k|
          expect(k).to be_a_config_key_entry
        end
      end

      it 'has the correct values in the KeyEntry instances' do
        expect(result[0]).to have_config_key_props('test', :any, 'hk.service_one.config_one.part_one', 'value_one')
        expect(result[1]).to have_config_key_props('test', :any, 'hk.service_one.config_one.part_two', 'value_two')
      end
    end

    context 'with multiple nested complex key config' do
      let(:cfg_yml) do
        %Q{
          "test.hk":
            "service_one.config_one":
              part_one: value_one
              part_two: value_two
            "service_two":
              "config_two.part_one": value_three
          "prod.us":
            "service_one.config_one": value_four
        }
      end

      it 'returns an array with four entries' do
        expect(result.count).to eq(4)
      end

      it 'returns only KeyEntry instance' do
        result.each do |k|
          expect(k).to be_a_config_key_entry
        end
      end

      it 'has the correct values in the KeyEntry instances' do
        expect(result[0]).to have_config_key_props('test', :any, 'hk.service_one.config_one.part_one', 'value_one')
        expect(result[1]).to have_config_key_props('test', :any, 'hk.service_one.config_one.part_two', 'value_two')
        expect(result[2]).to have_config_key_props('test', :any, 'hk.service_two.config_two.part_one', 'value_three')
        expect(result[3]).to have_config_key_props('prod', :any, 'us.service_one.config_one', 'value_four')
      end
    end

    context 'with wild card env' do
      let(:cfg_yml) do
        %Q{
          "*.hk":
            "service_one.config_one": value_one
        }
      end

      it 'returns an array with one entry' do
        expect(result.count).to eq(1)
      end

      it 'returns only KeyEntry instance' do
        result.each do |k|
          expect(k).to be_a_config_key_entry
        end
      end

      it 'has the correct values in the KeyEntry instances' do
        expect(result[0]).to have_config_key_props(:any, :any, 'hk.service_one.config_one', 'value_one')
      end
    end

    context 'with wild card as non-env component' do
      let(:cfg_yml) do
        %Q{
          "test.*":
            "service_one.config_one": value_one
        }
      end

      it 'raises an InvalidConfigKey error' do
        expect { result }.to raise_error AppConfigRails::InvalidConfigKey
      end
    end

    context 'with "use_domain" enabled' do
      let(:parser) { described_class.new(true) }

      context 'and simple config key' do
        let(:cfg_yml) do
          %Q{
          "test.hk":
            "service_one.config_one": value_one
        }
        end

        it 'returns an array with one entry' do
          expect(result.count).to eq(1)
        end

        it 'returns only KeyEntry instance' do
          result.each do |k|
            expect(k).to be_a_config_key_entry
          end
        end

        it 'has the correct values in the KeyEntry instances' do
          expect(result[0]).to have_config_key_props('test', 'hk', 'service_one.config_one', 'value_one')
        end
      end

      context 'with wild card env' do
        let(:cfg_yml) do
          %Q{
          "*.hk":
            "service_one.config_one": value_one
        }
        end

        it 'returns an array with one entry' do
          expect(result.count).to eq(1)
        end

        it 'returns only KeyEntry instance' do
          result.each do |k|
            expect(k).to be_a_config_key_entry
          end
        end

        it 'has the correct values in the KeyEntry instances' do
          expect(result[0]).to have_config_key_props(:any, 'hk', 'service_one.config_one', 'value_one')
        end
      end

      context 'with wild card domain' do
        let(:cfg_yml) do
          %Q{
          "test.*":
            "service_one.config_one": value_one
        }
        end

        it 'returns an array with one entry' do
          expect(result.count).to eq(1)
        end

        it 'returns only KeyEntry instance' do
          result.each do |k|
            expect(k).to be_a_config_key_entry
          end
        end

        it 'has the correct values in the KeyEntry instances' do
          expect(result[0]).to have_config_key_props('test', :any, 'service_one.config_one', 'value_one')
        end
      end

      context 'with wild card env and domain' do
        let(:cfg_yml) do
          %Q{
          "*.*":
            "service_one.config_one": value_one
        }
        end

        it 'returns an array with one entry' do
          expect(result.count).to eq(1)
        end

        it 'returns only KeyEntry instance' do
          result.each do |k|
            expect(k).to be_a_config_key_entry
          end
        end

        it 'has the correct values in the KeyEntry instances' do
          expect(result[0]).to have_config_key_props(:any, :any, 'service_one.config_one', 'value_one')
        end
      end

      context 'with wild card in non-env and non-domain component' do
        let(:cfg_yml) do
          %Q{
          "test.hk":
            "*.config_one": value_one
        }
        end

        it 'raises an InvalidConfigKey error' do
          expect { result }.to raise_error AppConfigRails::InvalidConfigKey
        end
      end
    end
  end
end