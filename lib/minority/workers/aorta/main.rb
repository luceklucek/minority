require 'bunny'

class AortaMainWorker
	include Sidekiq::Worker

	def initialize
		@conn = Bunny.new(ENV['AMQP_URL'])
	end

	def perform
		@conn.start
		ch = @conn.create_channel
		q = ch.queue(ENV['AMQP_QUEUE_NAME'], {durable: true})

			q.subscribe(block: false, manual_ack: true) do |delivery_info, properties, payload|
				message_type, message_details = JSON.parse(payload)

				case message_type
				when "freshdesk_check_ticket"
					# Let's just acknowledge this message so that RabbitMQ doesn't requeue it
					# After acknowledging, delegate the work to a specified worker

					ch.ack(delivery_info.delivery_tag)
					AortaCheckTicketWorker.perform_async(message_details["ticket_id"])
				else
				end

			end
	end

end