This was an assignment given by cipherschool

problem statment:

You are a DevOps engineer at a startup. The team runs several microservices on a Linux server.
The on-call rotation is exhausted from manually restarting services whenever they crash. Write a
production-grade Bash script that monitors a list of services, detects failures, attempts
auto-recovery, and logs everything to a structured log file.

How it works

1)Service List Input
Reads services from services.txt (one service per line)

2)Health Check
Uses systemctl is-active to verify if each service is running

3)Failure Detection & Recovery
:If a service is not active:
Attempts a restart using systemctl restart
Waits 5 seconds
Re-checks status
4)Logging (Structured)
.)Logs all events to:
bash command:-
/var/log/health_monitor.log
.)Uses JSON format with:
timestamp
severity (INFO, WARN, ERROR)
service name
message
5)Summary Output


Displays:
Total services checked
Healthy
Recovered
Failed







