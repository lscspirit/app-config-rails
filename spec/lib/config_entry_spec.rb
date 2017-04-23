require 'spec_helper'

RSpec.describe AppConfigLoader::ConfigEntry do
  def build_full_key(key_size, env, domain, use_domain = false)
    parts = [env]
    parts << domain if use_domain
    key_size.times { parts << Faker::Lorem.characters(10) }

    parts.join('.')
  end

  def compare_key_components(main_components, other_components)
    comp = main_components.count <=> other_components.count
    return comp if comp != 0

    main_components.each_index do |idx|
      comp = main_components[idx] <=> other_components[idx]
      return comp if comp != 0
    end
  end

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

  describe '#<=>' do
    subject { main <=> other }

    let(:use_domain) { [true, false].sample }
    let(:main)  { described_class.new main_key, Faker::Lorem.characters(10), use_domain }
    let(:other) { described_class.new other_key, Faker::Lorem.characters(10), use_domain }

    let(:key_size) { (1..6).to_a.sample(2) }
    let(:envs) { %w(test development production *).sample(2) }
    let(:domains) { [Faker::Lorem.characters(5), Faker::Lorem.characters(5)] }

    context 'with entries of different key size' do
      let(:main_key) { build_full_key key_size[0], envs[0], domains[0], use_domain }
      let(:other_key) { build_full_key key_size[1], envs[1], domains[1], use_domain }

      it 'returns the same comparison as the key size comparison' do
        expect(subject).to eq(compare_key_components(main.key_components, other.key_components))
      end
    end

    context 'with entries same key size but different key' do
      let(:main_key) { build_full_key key_size[0], envs[0], domains[0], use_domain }
      let(:other_key) { build_full_key key_size[0], envs[1], domains[1], use_domain }

      it 'returns the same comparison as the key component comparison' do
        expect(subject).to eq(compare_key_components(main.key_components, other.key_components))
      end
    end

    context 'with entries same key but different specificity' do
      let(:envs) { ['*', Faker::Lorem.characters(5)].shuffle }  # this guarantee one of the env is wildcard
      let(:main_key) { build_full_key key_size[0], envs[0], domains[0], use_domain }
      let(:other_key) { main_key.gsub(/^[^.]+/, envs[1]) }

      it 'returns the same comparison between the specificity of the two entries' do
        expect(subject).to eq(main.specificity <=> other.specificity)
      end
    end

    context 'with entries same key and specificity but different env' do
      let(:envs) { [Faker::Lorem.characters(5), Faker::Lorem.characters(5)] }
      let(:main_key) { build_full_key key_size[0], envs[0], domains[0], use_domain }
      let(:other_key) { main_key.gsub(/^[^.]+/, envs[1]) }

      it 'returns the lexcial comparison of the two envs' do
        expect(subject).to eq(envs[0] <=> envs[1])
      end
    end

    context 'with entries same key, specificity and env but different domain' do
      let(:use_domain) { true }
      let(:domains) { [Faker::Lorem.characters(5), Faker::Lorem.characters(5)] }
      let(:main_key) { build_full_key key_size[0], envs[0], domains[0], use_domain }
      let(:other_key) do
        parts = main_key.split('.')
        parts[1] = domains[1]
        parts.join('.')
      end

      it 'returns the lexical comparison of the two envs' do
        expect(subject).to eq(domains[0] <=> domains[1])
      end
    end
  end
end