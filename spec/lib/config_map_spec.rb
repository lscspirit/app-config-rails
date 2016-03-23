require 'spec_helper'

RSpec.describe AppConfigRails::ConfigMap do
  let(:map) { described_class.new }

  describe '#add' do
    let(:key_map) { map.instance_variable_get :@key_map }
    let(:existing_map) { nil }

    context 'when "overwrite" is set to false' do
      before :example do
        map.instance_variable_set :@key_map, existing_map if existing_map
        map.add new_entry
      end

      context 'and the entry uses a brand new key' do
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'value_one' }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end

      context 'and the entry (less specific) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'original_value' }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new '*.service_one', 'new_value' }

        it 'does not change the entry into the key map' do
          expect(key_map[:service_one]).to eq(existing)
        end
      end

      context 'and the entry (same specificity) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'original_value' }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'new_value' }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end

      context 'and the entry (greater specificity) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new '*.service_one', 'original_value' }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'new_value' }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end
    end

    context 'when "overwrite" is set to true' do
      before :example do
        map.instance_variable_set :@key_map, existing_map if existing_map
        map.add new_entry, true
      end

      context 'and the entry uses a brand new key' do
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'value_one' }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end

      context 'and the entry (less specific) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'original_value' }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new '*.service_one', 'new_value' }

        it 'does not change the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end

      context 'and the entry (same specificity) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'original_value' }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'new_value' }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end

      context 'and the entry (greater specificity) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new '*.service_one', 'original_value' }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'new_value' }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end
    end

    context 'when domain is in use' do
      before :example do
        map.instance_variable_set :@key_map, existing_map if existing_map
        map.add new_entry
      end

      context 'and the entry uses a brand new key' do
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.hk.service_one', 'value_one', true }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end

      context 'and the entry (less specific) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.hk.service_one', 'original_value', true }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.*.service_one', 'new_value', true }

        it 'does not change the entry into the key map' do
          expect(key_map[:service_one]).to eq(existing)
        end
      end

      context 'and the entry (same specificity) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.hk.service_one', 'original_value', true }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.hk.service_one', 'new_value', true }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end

      context 'and the entry (greater specificity) uses an existing key' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.*.service_one', 'original_value', true }
        let(:existing_map) { { service_one: existing } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.hk.service_one', 'new_value', true }

        it 'adds the entry into the key map' do
          expect(key_map[:service_one]).to eq(new_entry)
        end
      end
    end

    context 'with conflicting key' do
      let(:call_add) { map.add new_entry }

      before :example do
        map.instance_variable_set :@key_map, existing_map if existing_map
      end

      context 'that already have child config' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.level_one.level_two', 'original_value' }
        let(:existing_map) { { level_one: { level_two: existing } } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.level_one', 'new_value' }

        it 'raises ConfigKeyConflict error' do
          expect { call_add }.to raise_error(AppConfigRails::ConfigKeyConflict)
        end
      end

      context 'that already have an entry in the key parent component' do
        let(:existing) { AppConfigRails::ConfigEntry.new 'prod.level_one.level_two', 'original_value' }
        let(:existing_map) { { level_one: { level_two: existing } } }
        let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.level_one.level_two.level_three', 'new_value' }

        it 'raises ConfigKeyConflict error' do
          expect { call_add }.to raise_error(AppConfigRails::ConfigKeyConflict)
        end
      end
    end
  end

  describe '#<<' do
    let(:key_map) { map.instance_variable_get :@key_map }

    before :example do
      map.add new_entry
    end

    context 'with a brand new entry' do
      let(:new_entry) { AppConfigRails::ConfigEntry.new 'prod.service_one', 'value_one' }

      it 'adds the entry into the key map' do
        expect(key_map[:service_one]).to eq(new_entry)
      end
    end
  end

  describe '#get' do
    before :example do
      map.instance_variable_set :@key_map, key_map
    end

    context 'with single level key' do
      let(:key_map) {
        { level_one: 'value_one' }
      }

      context 'that exists' do
        it 'returns the right value' do
          expect(map.get('level_one')).to eq('value_one')
        end
      end

      context 'that does not exist' do
        it 'returns nil' do
          expect(map.get(Faker::Lorem.characters(5))).to be_nil
        end
      end
    end

    context 'with multi-level key' do
      let(:key_map) {
        { level_one: { level_two: 'value_one' } }
      }

      context 'that exists' do
        it 'returns the right value' do
          expect(map.get('level_one.level_two')).to eq('value_one')
        end
      end

      context 'that does not exist' do
        it 'returns nil' do
          key = "#{Faker::Lorem.characters(5)}.#{Faker::Lorem.characters(5)}"
          expect(map.get(key)).to be_nil
        end
      end
    end

    context 'with a partial key' do
      let(:key_map) {
        { level_one: { level_two: { level_three: 'value_one' } } }
      }

      context 'that exists' do
        it 'returns the children of the key' do
          expect(map.get('level_one.level_two')).to eq({ level_three: 'value_one' })
        end
      end

      context 'that does not exist' do
        it 'returns nil' do
          key = "level_one.#{Faker::Lorem.characters(5)}"
          expect(map.get(key)).to be_nil
        end
      end
    end

    context 'with a key deeper than any key in the map' do
      let(:key_map) {
        { level_one: { level_two: 'value_one' } }
      }

      it 'returns nil' do
        expect(map.get('level_one.level_two.level_three')).to be_nil
      end
    end
  end

  describe '#[]' do
    before :example do
      map.instance_variable_set :@key_map, key_map
    end

    context 'with simple config key' do
      let(:key_map) {
        { level_one: 'value_one' }
      }

      it 'returns the right value' do
        expect(map['level_one']).to eq('value_one')
      end
    end
  end

  describe '#to_a' do
    before :example do
      map.instance_variable_set :@key_map, {
        level_one_a: { level_two_a_1: 'value_a_1', level_two_a_2: 'value_a_2' },
        level_one_b: 'value_b_1'
      }
    end

    it 'returns an array of all the value in the config map' do
      expect(map.to_a).to eq(['value_a_1', 'value_a_2', 'value_b_1'])
    end
  end

  describe '#merge' do
    let(:original_map) do
      map = described_class.new
      map << AppConfigRails::ConfigEntry.new('hk.config_one', 'value_one')
      map << AppConfigRails::ConfigEntry.new('hk.level_one.level_two.config_two', 'value_two')
      map << AppConfigRails::ConfigEntry.new('hk.service_one.config_three', 'value_three')
      map
    end

    context 'with a target map that has no conflicting key' do
      let(:target_map) do
        map = described_class.new
        map << AppConfigRails::ConfigEntry.new('hk.config_one', 'new_value_one')
        map << AppConfigRails::ConfigEntry.new('hk.service_one.config_three', 'new_value_three')
        map
      end

      before :example do
        original_map.merge(target_map)
      end

      it 'updates the merged entries in the original map' do
        expect(original_map['config_one']).to eq(AppConfigRails::ConfigEntry.new('hk.config_one', 'new_value_one'))
        expect(original_map['service_one.config_three']).to eq(AppConfigRails::ConfigEntry.new('hk.service_one.config_three', 'new_value_three'))
      end

      it 'leaves the unmerged entries untouched' do
        expect(original_map['level_one.level_two.config_two']).to eq(AppConfigRails::ConfigEntry.new('hk.level_one.level_two.config_two', 'value_two'))
      end
    end

    context 'with a target map that has conflicting key' do
      let(:target_map) do
        map = described_class.new
        map << AppConfigRails::ConfigEntry.new('hk.config_one.conflict_one', 'new_value_one')
        map
      end

      it 'raises ConfigKeyConflict error' do
        expect { original_map.merge(target_map) }.to raise_error(AppConfigRails::ConfigKeyConflict)
      end
    end
  end
end