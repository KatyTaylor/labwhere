# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManifestUploader, type: :model do
  let!(:locations)         { create_list(:unordered_location_with_parent, 10) }
  let!(:ordered_locations) { create_list(:ordered_location_with_parent, 10) }
  let(:new_ordered_location) { build(:ordered_location, barcode: 'unknown') }
  let(:new_location)       { build(:unordered_location, barcode: 'unknown') }
  let!(:less_positions)    { Array.new(4) {|i| i+1 } }
  let!(:equal_positions)   { Array.new(5) {|i| i+1 } }
  let(:labware_prefix)     { 'RNA' }
  let!(:scientist)         { create(:scientist) }
  let(:manifest_uploader)  { ManifestUploader.new(user: scientist) }

  context 'with unordered locations that all exist' do
    let!(:manifest) { build(:csv_manifest, locations: locations, number_of_labwares: 5, labware_prefix: labware_prefix).generate_csv }

    attr_reader :data

    before(:each) do
      manifest_uploader.file = manifest
      manifest_uploader.run
    end

    it 'will create all of the labwares' do
      labwares = Labware.where("barcode LIKE '%#{labware_prefix}%'")
      expect(labwares.count).to eq(50)
    end

    it 'will add all of the labwares to the locations' do
      locations.each do |location|
        expect(location.labwares.count).to eq(5)
      end
    end

    it 'will create audit records for the labwares' do
      labwares = Labware.where("barcode LIKE '%#{labware_prefix}%'")
      expect(labwares.first.audits.last.action).to eq("Uploaded from manifest")
      expect(labwares.last.audits.last.action).to eq("Uploaded from manifest")
    end
  end

  context 'when there is a location that is not valid' do
    let!(:manifest) { build(:csv_manifest, locations: locations + [new_location], number_of_labwares: 5, labware_prefix: labware_prefix).generate_csv }

    attr_reader :data

    before(:each) do
      manifest_uploader.file = manifest
    end

    it 'will not be valid' do
      expect(manifest_uploader).to_not be_valid
    end

    it 'will show an error' do
      manifest_uploader.run
      expect(manifest_uploader.errors.full_messages).to include("location(s) with barcode #{new_location.barcode} do not exist")
    end

    it 'will not create any labwares' do
      manifest_uploader.run
      labwares = Labware.where("barcode LIKE '%#{labware_prefix}%'")
      expect(labwares).to be_empty
    end
  end

  context 'with ordered locations which all exist' do
    let!(:manifest) { build(:csv_manifest, locations: ordered_locations, number_of_labwares: 5, labware_prefix: labware_prefix, positions: equal_positions).generate_csv }

    attr_reader :data

    before(:each) do
      manifest_uploader.file = manifest
      manifest_uploader.run
    end

    it 'will add the labwares to the defined positions' do
      labwares = Labware.where("coordinate_id IS NOT NULL")
      expect(labwares.count).to eq(50)
    end
  end

  context 'when there is no position defined for an ordered location' do
    let!(:test_locations) { create_list(:ordered_location_with_parent, 1) }
    let!(:manifest) { build(:csv_manifest, locations: test_locations, number_of_labwares: 1, labware_prefix: labware_prefix, positions: [] ).generate_csv }

    attr_reader :data

    before(:each) do
      manifest_uploader.file = manifest
    end

    it 'will not be valid' do
      expect(manifest_uploader).to_not be_valid
    end

    it 'will show an error' do
      manifest_uploader.run
      expect(manifest_uploader.errors.full_messages).to include("position not defined for labware with barcode RNA000001")
    end
  end

  context 'when a position does not exist' do
    let!(:test_location) { create_list(:ordered_location_with_parent, 1) }
    let!(:manifest) { build(:csv_manifest, locations: test_location, number_of_labwares: 1, labware_prefix: labware_prefix, positions: [20] ).generate_csv }

    attr_reader :data

    before(:each) do
      manifest_uploader.file = manifest
    end

    it 'will not be valid' do
      expect(manifest_uploader).to_not be_valid
    end

    it 'will show an error' do
      manifest_uploader.run
      expect(manifest_uploader.errors.full_messages).to include("target position 20 for location with barcode #{test_location[0].barcode} does not exist")
    end
  end

  context 'when there are duplicate positions entered' do
  end
end
