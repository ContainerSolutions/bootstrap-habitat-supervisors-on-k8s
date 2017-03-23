#!/usr/bin/env ruby
$stdout.sync = true
$stderr.sync = true

def main
  supervisor_path = find_supervisor_binary
  package_name     = get_env("HAB_PACKAGE_NAME", example_value: "moretea/k8s-sup-bootstrap")
  statefulset_name = get_env("STATEFULSET_NAME", example_value: "hab-sup-bootstrap-set")
  service_name     = get_env("SERVICE_NAME", example_value: "hab-bootstrap")
  pod_ip           = get_pod_ip
  nr               = find_statefulset_pod_nr(statefulset_name: statefulset_name)

  if nr == 0
    puts "Starting as initial node"
    cmd = "#{supervisor_path} start #{package_name} -I --listen-gossip #{pod_ip}"
  else
    # Compute to which "previous" nodes it must connect
    connect_to = (0...nr).map do |i|
        statefulset_name + "-#{i}" + "." + "#{service_name}.default.svc.cluster.local"
    end

    puts "Starting as node #{nr}"
    puts "Connecting to #{connect_to.join(", ")}"

    peers = connect_to.map { |x| "--peer #{x}" }.join(" ")

    cmd = "#{supervisor_path} start #{package_name} -I #{peers} --listen-gossip #{pod_ip}"
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

def get_env(key, example_value:)
  val = ENV[key]

  if val.nil? || val == ""
    $stderr.puts "NO #{key} env var set!"
    puts <<-EOF
      You need to add sometying to your container spec, eg:
      env:
        - name: #{key}
          value: #{example_value}
    EOF
  else
    val
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

def find_statefulset_pod_nr(statefulset_name:)
  pod_name = get_pod_name
  match_regex = /#{statefulset_name}-(?<nr>\d+)/
  if (match = match_regex.match(pod_name)).nil?
    $stderr.puts "Could not extract node index from statefullset pod name!"
    exit 1
  else
    return match["nr"].to_i
  end
end

main
