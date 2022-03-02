require 'rails_helper'
require 'webhooks/twitter'

describe Webhooks::InstagramEventsJob do
  subject(:instagram_webhook) { described_class }

  before do
    stub_request(:post, /graph.facebook.com/)
    stub_request(:get, 'https://imagekit.io/blog/content/images/2020/05/media_library.jpeg')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Down/5.3.0'
        }
      )
      .to_return(status: 200, body: '', headers: {})
  end

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:dm_params) { build(:instagram_message_create_event).with_indifferent_access }
  let!(:test_params) { build(:instagram_test_text_event).with_indifferent_access }
  let!(:attachment_params) { build(:instagram_message_attachment_event).with_indifferent_access }
  let(:fb_object) { double }

  describe '#perform' do
    context 'with direct_message params' do
      it 'creates incoming message in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          {
            name: 'Jane',
            id: 'Sender-id-1',
            account_id: instagram_inbox.account_id,
            profile_pic: 'https://chatwoot-assets.local/sample.png'
          }.with_indifferent_access
        )
        instagram_webhook.perform_now(dm_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.conversations.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
      end

      it 'creates test text message in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          {
            name: 'Jane',
            id: 'Sender-id-1',
            account_id: instagram_inbox.account_id,
            profile_pic: 'https://chatwoot-assets.local/sample.png'
          }.with_indifferent_access
        )
        instagram_webhook.perform_now(test_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.content).to eq('This is a test message from facebook.')
      end

      it 'creates incoming message with attachments in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          {
            name: 'Jane',
            id: 'Sender-id-1',
            account_id: instagram_inbox.account_id,
            profile_pic: 'https://chatwoot-assets.local/sample.png'
          }.with_indifferent_access
        )
        instagram_webhook.perform_now(attachment_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.attachments.count).to be 1
      end
    end
  end
end
