describe DialogFieldDropDownList do
  context "dialog_field_drop_down_list" do
    before(:each) do
      @df = FactoryGirl.create(:dialog_field_sorted_item, :label => 'drop_down_list', :name => 'drop_down_list')
    end

    it "sort_by" do
      expect(@df.sort_by).to eq(:description)
      @df.sort_by = :none
      expect(@df.sort_by).to eq(:none)
      @df.sort_by = :value
      expect(@df.sort_by).to eq(:value)
      expect { @df.sort_by = :data }.to raise_error(RuntimeError)
      expect(@df.sort_by).to eq(:value)
    end

    it "sort_order" do
      expect(@df.sort_order).to eq(:ascending)
      @df.sort_order = :descending
      expect(@df.sort_order).to eq(:descending)
      expect { @df.sort_order = :mixed }.to raise_error(RuntimeError)
      expect(@df.sort_order).to eq(:descending)
    end

    it "return sorted values array as strings" do
      @df.data_type = "string"
      @df.values = [["2", "Y"], ["1", "Z"], ["3", "X"]]
      expect(@df.values).to eq([["3", "X"], ["2", "Y"], ["1", "Z"]])
      @df.sort_order = :descending
      expect(@df.values).to eq([["1", "Z"], ["2", "Y"], ["3", "X"]])

      @df.sort_by = :value
      @df.sort_order = :ascending
      expect(@df.values).to eq([["1", "Z"], ["2", "Y"], ["3", "X"]])
      @df.sort_order = :descending
      expect(@df.values).to eq([["3", "X"], ["2", "Y"], ["1", "Z"]])

      @df.sort_by = :none
      @df.sort_order = :ascending
      expect(@df.values).to eq([["2", "Y"], ["1", "Z"], ["3", "X"]])
      @df.sort_order = :descending
      expect(@df.values).to eq([["2", "Y"], ["1", "Z"], ["3", "X"]])
    end

    it "return sorted values array as integers" do
      @df.data_type = "integer"
      @df.values = [["2", "Y"], ["10", "Z"], ["3", "X"]]

      @df.sort_by = :value
      @df.sort_order = :ascending
      expect(@df.values).to eq([["2", "Y"], ["3", "X"], ["10", "Z"]])
      @df.sort_order = :descending
      expect(@df.values).to eq([["10", "Z"], ["3", "X"], ["2", "Y"]])

      @df.sort_by = :none
      @df.sort_order = :ascending
      expect(@df.values).to eq([["2", "Y"], ["10", "Z"], ["3", "X"]])
      @df.sort_order = :descending
      expect(@df.values).to eq([["2", "Y"], ["10", "Z"], ["3", "X"]])
    end

    context "#initialize_with_values" do
      before(:each) do
        @df.values = [["3", "X"], ["2", "Y"], ["1", "Z"]]
        @df.load_values_on_init = true
      end

      it "uses the first as the default value" do
        @df.default_value = nil
        @df.initialize_with_values({})
        expect(@df.value).to eq("3")
      end

      it "with default value" do
        @df.default_value = "1"
        @df.initialize_with_values({})
        expect(@df.value).to eq("1")
      end

      it "uses the first when there is a non-matching default value" do
        @df.default_value = "4"
        @df.initialize_with_values({})
        expect(@df.value).to eq("3")
      end
    end

    it "#automate_key_name" do
      expect(@df.automate_key_name).to eq("dialog_drop_down_list")
    end
  end

  describe "#refresh_json_value" do
    let(:dialog_field) { described_class.new(:dynamic => dynamic, :read_only => true) }

    context "dynamic" do
      let(:dynamic) { true }
      context "array" do
        context "included" do
          # TODO
        end
        context "not-included" do
          # TODO
        end
      end

      context "not-array" do
        before do
          allow(DynamicDialogFieldValueProcessor).to receive(:values_from_automate).with(dialog_field).and_return(
            [["123", 456], ["789", 101]]
          )
          dialog_field.value = "123"
        end

        it "sets the value" do
          dialog_field.refresh_json_value("789")
          expect(dialog_field.value).to eq("789")
        end

        it "returns the values from automate" do
          expect(dialog_field.refresh_json_value("789")).to eq(
            :refreshed_values => [["789", 101], ["123", 456]],
            :checked_value    => "789",
            :read_only        => true,
            :visible          => true
          )
        end
      end
    end

    context "non-dynamic" do
      let(:dynamic) { false }
      context "array" do
        context "included" do
          # TODO
        end
        context "not-included" do
          # TODO
        end
      end

      context "not-array" do
        context "when the dialog_field is not dynamic" do
          let(:dynamic) { false }

          before do
            dialog_field.values = [["123", 456], ["789", 101]]
            dialog_field.value = "123"
          end

          it "sets the value" do
            dialog_field.refresh_json_value("789")
            expect(dialog_field.value).to eq("789")
          end

          it "returns the values" do
            expect(dialog_field.refresh_json_value("789")).to eq(
              :refreshed_values => [["789", 101], ["123", 456]],
              :checked_value    => "789",
              :read_only        => true,
              :visible          => true
            )
          end
        end
      end
    end
  end

  describe "#values" do
    let(:dialog_field) { described_class.new(:dynamic => dynamic) }

    context "when the dialog_field is dynamic" do
      let(:dynamic) { true }

      before do
        allow(DynamicDialogFieldValueProcessor).to receive(:values_from_automate).with(dialog_field).and_return(%w(automate values))
      end

      context "when the raw values are already set" do
        before do
          dialog_field.instance_variable_set(:@raw_values, %w(potato potato))
        end

        it "returns the raw values" do
          expect(dialog_field.values).to eq(%w(potato potato))
        end
      end

      context "when the raw values are not already set" do
        it "returns the values from automate" do
          expect(dialog_field.values).to eq(%w(automate values))
        end
      end
    end

    context "when the dialog_field is not dynamic" do
      let(:dynamic) { false }

      context "when the raw values are already set" do
        before do
          dialog_field.instance_variable_set(:@raw_values, %w(potato potato))
        end

        it "returns the raw values" do
          expect(dialog_field.values).to eq(%w(potato potato))
        end
      end

      context "dialog field dropdown without options hash" do
        before do
          @df = FactoryGirl.create(:dialog_field_drop_down_list, :name => 'test drop down')
        end

        describe "#force_multi_value" do
          context "when force_multi_value is present" do
            context "when force_multi_value is null" do
              it "multivalue false" do
                expect(@df.force_multi_value).to be_falsey
              end
            end

            context "when force_multi_value is not null" do
              context "when force_multi_value is truthy" do
                it "multivalue true" do
                  @df.force_multi_value = true
                  expect(@df.force_multi_value).to be_truthy
                end
              end

              context "when force_multi_value is falsy" do
                it "multivalue false" do
                  expect(@df.force_multi_value).to be_falsey
                end
              end
            end
          end

          context "when force_multi_value is not present" do
            it "multivalue false" do
              expect(@df.force_multi_value).to be_falsey
            end
          end
        end
      end

      context "dialog field dropdown with options hash" do
        before do
          @df = FactoryGirl.create(:dialog_field_drop_down_list,
                                   :name    => 'test drop down',
                                   :options => {:force_multi_value => true})
        end

        it "#force_multi_value" do
          expect(@df.force_multi_value).to be_truthy
        end
      end

      context "when the raw values are not already set" do
        before do
          dialog_field.values = %w(original values)
        end

        it "returns the values" do
          expect(dialog_field.values).to eq(%w(original values))
        end
      end
    end
  end

  describe "#trigger_automate_value_updates" do
    let(:dialog_field) { described_class.new(:dynamic => dynamic) }

    context "when the dialog_field is dynamic" do
      let(:dynamic) { true }

      before do
        allow(DynamicDialogFieldValueProcessor).to receive(:values_from_automate).with(dialog_field).and_return(
          %w(automate values)
        )
      end

      context "when the raw values are already set" do
        before do
          dialog_field.instance_variable_set(:@raw_values, %w(potato potato))
        end

        it "updates with the values from automate" do
          expect(dialog_field.trigger_automate_value_updates).to eq(%w(automate values))
        end
      end

      context "when the raw values are not already set" do
        it "returns the values from automate" do
          expect(dialog_field.trigger_automate_value_updates).to eq(%w(automate values))
        end
      end
    end

    context "when the dialog_field is not dynamic" do
      let(:dynamic) { false }

      context "when the raw values are already set" do
        before do
          dialog_field.instance_variable_set(:@raw_values, %w(potato potato))
          dialog_field.values = %w(original values)
        end

        it "returns the raw values" do
          expect(dialog_field.trigger_automate_value_updates).to eq(%w(original values))
        end
      end

      context "when the raw values are not already set" do
        before do
          dialog_field.values = [%w(original values)]
        end

        it "returns the values" do
          expect(dialog_field.trigger_automate_value_updates).to eq([%w(original values)])
        end

        it "sets up the default value" do
          dialog_field.trigger_automate_value_updates
          expect(dialog_field.default_value).to eq("original")
        end
      end

      context "when the raw values are nil" do
        before do
          dialog_field.values = nil
        end

        it "sets the default value to nil without blowing up" do
          dialog_field.trigger_automate_value_updates
          expect(dialog_field.default_value).to eq(nil)
        end
      end
    end
  end
end