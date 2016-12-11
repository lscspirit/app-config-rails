require 'spec_helper'

RSpec.describe AppConfigLoader::ConfigEntry do
  describe '#applicable?' do
    let(:result) { entry.applicable?(*params) }

    context 'without domain' do
      context 'on a specific entry' do
        let(:entry) { described_class.new 'test_env.test_domain.test_key', 'test_value' }

        context 'when the env matches' do
          let(:params) { ['test_env'] }

          it 'returns true' do
            expect(result).to be_truthy
          end
        end

        context 'when the env does not matches' do
          let(:params) { [Faker::Lorem.characters(10)] }

          it 'returns false' do
            expect(result).to be_falsey
          end
        end
      end

      context 'on a entry with wild card env' do
        let(:entry) { described_class.new '*.test_domain.test_key', 'test_value' }

        context 'against any env' do
          let(:params) { [Faker::Lorem.characters(10)] }

          it 'returns true' do
            expect(result).to be_truthy
          end
        end
      end
    end

    context 'with domain' do
      context 'on a specific entry' do
        let(:entry) { described_class.new 'test_env.test_domain.test_key', 'test_value', true }

        context 'when the env and domain match' do
          let(:params) { ['test_env', 'test_domain'] }

          it 'returns true' do
            expect(result).to be_truthy
          end
        end

        context 'when the env does not match, but domain does' do
          let(:params) { [Faker::Lorem.characters(10), 'test_domain'] }

          it 'returns false' do
            expect(result).to be_falsey
          end
        end

        context 'when the env matches, but domain does not' do
          let(:params) { ['test_env', Faker::Lorem.characters(10)] }

          it 'returns false' do
            expect(result).to be_falsey
          end
        end

        context 'when both env and domin do not match' do
          let(:params) { [Faker::Lorem.characters(10), Faker::Lorem.characters(10)] }

          it 'returns false' do
            expect(result).to be_falsey
          end
        end
      end

      context 'on a entry with wild card env' do
        let(:entry) { described_class.new '*.test_domain.test_key', 'test_value', true }

        context 'when the env is random and domain matches' do
          let(:params) { [Faker::Lorem.characters(10), 'test_domain'] }

          it 'returns true' do
            expect(result).to be_truthy
          end
        end

        context 'when the env is random, but domain does not match' do
          let(:params) { [Faker::Lorem.characters(10), Faker::Lorem.characters(10)] }

          it 'returns false' do
            expect(result).to be_falsey
          end
        end
      end

      context 'on a entry with wild card domain' do
        let(:entry) { described_class.new 'test_env.*.test_key', 'test_value', true }

        context 'when the env matches and domain is random' do
          let(:params) { ['test_env', Faker::Lorem.characters(10)] }

          it 'returns true' do
            expect(result).to be_truthy
          end
        end

        context 'when the env does not match, and the domain is random' do
          let(:params) { [Faker::Lorem.characters(10), Faker::Lorem.characters(10)] }

          it 'returns false' do
            expect(result).to be_falsey
          end
        end
      end

      context 'on a entry with wild card env and domain' do
        let(:entry) { described_class.new '*.*.test_key', 'test_value', true }

        context 'when the env and the domain are random' do
          let(:params) { [Faker::Lorem.characters(10), Faker::Lorem.characters(10)] }

          it 'returns true' do
            expect(result).to be_truthy
          end
        end
      end
    end
  end
end