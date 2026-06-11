# frozen_string_literal: true

module IPTestHelpers
  # Generate a random RFC1918 (private) IPv4 address.
  # Covers: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
  def rfc1918_ip
    case rand(3)
    when 0
      "10.#{rand(0..255)}.#{rand(0..255)}.#{rand(1..254)}"
    when 1
      "172.#{rand(16..31)}.#{rand(0..255)}.#{rand(1..254)}"
    else
      "192.168.#{rand(0..255)}.#{rand(1..254)}"
    end
  end

  alias private_ip_v4_address rfc1918_ip

  # Generate a random public IPv4 address (avoids RFC1918, loopback and link-local ranges).
  def public_ip_v4_address # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    loop do
      a = rand(1..223)
      b = rand(0..255)
      c = rand(0..255)
      d = rand(1..254)

      next if a == 10
      next if a == 127
      next if a == 169 && b == 254
      next if a == 172 && (16..31).cover?(b)
      next if a == 192 && b == 168

      return "#{a}.#{b}.#{c}.#{d}"
    end
  end
end
