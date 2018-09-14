require "amqp"

class QueueChannels

  @@exchange_name : String = "logs"
  @@queue_name : String = "logs"
  @@config : AMQP::Config = AMQP::Config.new("queue")

  @exchange : AMQP::Exchange | Nil
  @queue : AMQP::Queue | Nil

  getter queue : AMQP::Queue | Nil

  def initialize
    AMQP::Connection.start(@@config) do |conn|
      channel = conn.channel
      @exchange = channel.direct(@@exchange_name)
      @queue = channel.queue(@@queue_name)
      if queue = @queue
        queue.bind(@exchange, queue.name)
      end
    end
  end

  def send_to(msg)
    if exchange = @exchange
      msg = AMQP::Message.new(msg)
      exchange.publish(msg, @@queue_name)
    end
  end
end
