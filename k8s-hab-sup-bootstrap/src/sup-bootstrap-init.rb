#!/usr/bin/env ruby
$stdout.sync = true
$stderr.sync = true

STATEFULSET_NAME = ENV["STATEFULSET_NAME"] || "hab-sup-bootstrap"

def main
  pod_name = get_pod_name
  pod_ip = get_pod_ip

  match_regex = /#{STATEFULSET_NAME}-(?<nr>\d+)/
  if (match = match_regex.match(pod_name)).nil?
    $stderr.puts "Could not extract node index from statefullset pod name!"
    exit 1
  else
    nr = match["nr"].to_i
  end

  supervisor_path = find_supervisor_binary

  if nr == 0
    puts "Starting as initial node"
    cmd = "#{supervisor_path} start -I --listen-gossip #{pod_ip} #{PAUSE_PACKGE}"
  else
    connect_to = (0...nr).map do |i|  
        STATEFULSET_NAME + "-#{i}" + "." + "hab-bootstrap.default.svc.cluster.local"
    end

    puts "Starting as node #{nr}"
    puts "Connecting to #{connect_to.join(", ")}"

    peers = connect_to.map { |x| "--peer #{x}" }.join(" ")

    cmd = "#{supervisor_path} start -I #{peers} --listen-gossip #{pod_ip} #{PAUSE_PACKGE}"
  end

  puts "Execing #{cmd}"
  exec cmd
end

def get_pod_ip
  pod_ip = ENV["POD_IP"] 

  if pod_ip.nil? || pod_ip == ""
    $stderr.puts "No POD_IP env var available!"

    puts <<-EOF
    Add the following to your container spec:
      env:
       - name: POD_IP
         valueFrom:
         fieldRef:
           apiVersion: v1
           fieldPath: status.podIP
    EOF
    exit 1
  else
    pod_ip
  end
end

def get_pod_name
  pod_name = ENV["POD_NAME"] 

  if pod_name.nil? || pod_name == ""
    $stderr.puts "No POD_NAME env var available!"

    puts <<-EOF
    Add the following to your container spec:
      env:
       - name: POD_NAME
         valueFrom:
         fieldRef:
           fieldPath: metadata.name
    EOF
    exit 1
  else
    pod_name
  end
end

def find_supervisor_binary
  # Find hab supervisor
  hab_supervisors = Dir["/hab/pkgs/core/hab-sup/*/*/bin/hab-sup"]

  if hab_supervisors.length == 0
    $stderr.puts "No supervisor found"
    exit 1
  elsif hab_supervisors.length > 1
    $stderr.puts "More than one supervisor version found"
    exit 1
  else
    hab_supervisors.first
  end
end

main
