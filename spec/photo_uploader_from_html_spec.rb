require 'spec_helper'
describe PhotoUploaderFromHtml do
  xdescribe '.run' do
    it { expect { PhotoUploaderFromHtml.run }.to output("hello world\n").to_stdout }
  end

  describe '.replace' do
    context 'given `hello`' do
      it { expect(PhotoUploaderFromHtml.replace('hello')).to eq('hello') }
    end

    context 'given img tag' do
      let(:string){ %(<img width=240 src='http://example.com/1.jpg'>) }
      it do
        expect(PhotoUploaderFromHtml).to receive(:upload)
        .with('http://example.com/1.jpg').and_return('tumbler_url')

        expect(PhotoUploaderFromHtml.replace(string)).to \
          eq(%(<img width=240 src='tumbler_url'>))
      end
    end

    context 'given img tag' do
      let(:string){ %(<img width="240" src='http://example.com/1.jpg'>) }
      it do
        expect(PhotoUploaderFromHtml).to receive(:upload)
        .with('http://example.com/1.jpg').and_return('tumbler_url')

        expect(PhotoUploaderFromHtml.replace(string)).to \
          eq(%(<img width="240" src='tumbler_url'>))
      end
    end

    context 'given img tag' do
      let(:string){ %(<img width="240" src="http://example.com/1.jpg">) }
      it do
        expect(PhotoUploaderFromHtml).to receive(:upload)
        .with('http://example.com/1.jpg').and_return('tumbler_url')

        expect(PhotoUploaderFromHtml.replace(string)).to \
          eq(%(<img width="240" src='tumbler_url'>))
      end
    end
  end

  describe '.upload' do
    it 'calls .do_upload(orig_url) and calls .scrape(id)' do
      expect(PhotoUploaderFromHtml).to receive(:do_upload)
      .with('http://example.com/1.jpg').and_return('id_1234').ordered
      expect(PhotoUploaderFromHtml).to receive(:scrape)
      .with('id_1234').and_return('http://target.tumbler.com/hoge.jpg').ordered

      expect(
        PhotoUploaderFromHtml.upload('http://example.com/1.jpg')
      ).to eq('http://target.tumbler.com/hoge.jpg')
    end
  end

  describe '.do_upload' do
    it 'calls .guess_content_type(orig_url) and calls .photo(content_type)' do
      expect(PhotoUploaderFromHtml).to receive(:guess_content_type)
      .with('http://example.com/1.jpg').and_return('image/jpeg').ordered
      expect(PhotoUploaderFromHtml).to receive(:photo)
      .with('http://example.com/1.jpg', 'image/jpeg').and_return('id_1234').ordered

      expect(
        PhotoUploaderFromHtml.do_upload('http://example.com/1.jpg')
      ).to eq('id_1234')
    end
  end

  describe '.guess_content_type' do
    context 'given ".jpg"' do
      it do
        expect(PhotoUploaderFromHtml.guess_content_type('http://example.com/1.jpg'))
        .to eq('image/jpeg')
      end
    end

    context 'given ".gif"' do
      it do
        expect(PhotoUploaderFromHtml.guess_content_type('http://example.com/1.gif'))
        .to eq('image/gif')
      end
    end

    context 'given ".gif?xx=yy"' do
      it do
        expect(PhotoUploaderFromHtml.guess_content_type('http://example.com/1.gif?xx=yy'))
        .to eq('image/gif')
      end
    end

    context 'given ".jpg:large"' do
      it do
        expect(PhotoUploaderFromHtml.guess_content_type('http://example.com/1.jpg:large'))
        .to eq('image/jpeg')
      end
    end

    context 'given ".png"' do
      it do
        expect(PhotoUploaderFromHtml.guess_content_type('http://example.com/1.png'))
        .to eq('image/png')
      end
    end

    context 'given "1"' do
      it do
        expect(PhotoUploaderFromHtml.guess_content_type('http://example.com/1'))
        .to eq('image/jpeg')
      end
    end

    context 'given "1.zip"' do
      it do
        expect{
          PhotoUploaderFromHtml.guess_content_type('http://example.com/1.zip')
        }.to raise_error PhotoUploaderFromHtml::UnknownContentType
      end
    end

    xdescribe '.photo' do
    end

    describe '.scrape' do
      it 'calls .build_uri(id) and calls .try_scrape_three_times(uri)' do
        expect(PhotoUploaderFromHtml).to receive(:build_uri)
        .with('id_1234').and_return('http://my.tumbler.com/id_1234').ordered
        expect(PhotoUploaderFromHtml).to receive(:try_scrape_three_times)
        .with('http://my.tumbler.com/id_1234').and_return('http://target.tumbler.com/hoge.jpg').ordered

        expect(
          PhotoUploaderFromHtml.scrape('id_1234')
        ).to eq('http://target.tumbler.com/hoge.jpg')
      end
    end

    describe '.build_uri' do
      context 'given "id_1234"' do
        it do
          expect(PhotoUploaderFromHtml).to receive(:host).and_return('my.tumblr.com')
          expect(
            PhotoUploaderFromHtml.build_uri('id_1234')
          ).to eq('http://my.tumblr.com/id_1234')
        end
      end
    end

    describe '.try_scrape_three_times' do
      describe 'calls .do_scrape 3 times at most' do
        context 'no error raises in first try' do
          it do
            expect(PhotoUploaderFromHtml).to receive(:do_scrape)
            .with('http://my.tumblr.com/id_1234').exactly(1).times.and_return('http://target.tumbler.com/hoge.jpg')

            expect(
              PhotoUploaderFromHtml.try_scrape_three_times('http://my.tumblr.com/id_1234')
            ).to eq('http://target.tumbler.com/hoge.jpg')
          end
        end

        context 'error raises in first try' do
          it do
            expect(PhotoUploaderFromHtml).to receive(:do_scrape)
            .with('http://my.tumblr.com/id_1234').exactly(1).and_raise('http://target.tumbler.com/hoge.jpg')

            expect(PhotoUploaderFromHtml).to receive(:do_scrape)
            .with('http://my.tumblr.com/id_1234').exactly(1).and_return('http://target.tumbler.com/hoge.jpg')

            expect(
              PhotoUploaderFromHtml.try_scrape_three_times('http://my.tumblr.com/id_1234')
            ).to eq('http://target.tumbler.com/hoge.jpg')
          end
        end
      end
    end
  end
end

describe 'command' do
  it do
    allow(PhotoUploaderFromHtml)
    .to receive(:raplace)

    expect(
      %x(echo 'hello' | bundle exec ./bin/photo_uploader_from_html)
    ).to eq("hello\n")
  end

  it do
    allow(PhotoUploaderFromHtml)
    .to receive(:raplace)

    expect(
      %x(echo "hello\nworld" | bundle exec ./bin/photo_uploader_from_html)
    ).to eq("hello\nworld\n")
  end
end
