describe BbCodes::Tags::ListTag do
  let(:tag) { BbCodes::Tags::ListTag.instance }

  describe '#format' do
    context 'with [list]' do
      subject { tag.format '[list][*]первая строка[*]вторая строка[/list]' }
      it { is_expected.to eq '<ul class="b-list"><li>первая строка</li><li>вторая строка</li></ul>' }
    end

    context '[list] br after' do
      subject { tag.format "[list][*]первая строка[/list]\n" }
      it { is_expected.to eq '<ul class="b-list"><li>первая строка</li></ul>' }
    end

    context '[*] only' do
      subject { tag.format '[*]первая строка[*]вторая строка' }
      it { is_expected.to eq '<ul class="b-list"><li>первая строка</li></ul><ul class="b-list"><li>вторая строка</li></ul>' }
    end

    context '[*] with brs' do
      subject { tag.format "[*]первая строка\ntest\n\ntest2" }
      it { is_expected.to eq "<ul class=\"b-list\"><li>первая строка\ntest</li></ul>\ntest2" }
    end
  end
end
