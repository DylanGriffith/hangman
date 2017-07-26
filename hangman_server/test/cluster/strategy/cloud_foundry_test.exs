defmodule Cluster.Strategy.CloudFoundryTest do
  use ExUnit.Case
  import Cluster.Strategy.CloudFoundry

  test "#parse_nodes" do
    response = """
      {
         "0": {
            "state": "RUNNING",
            "isolation_segment": null,
            "stats": {
               "name": "test-app-cluster",
               "uris": [
                  "test-app-cluster.cfapps.io"
               ],
               "host": "10.10.100.120",
               "port": 61020,
               "uptime": 9,
               "mem_quota": 536870912,
               "disk_quota": 1073741824,
               "fds_quota": 16384,
               "usage": {
                  "time": "2017-07-26T08:18:54+00:00",
                  "cpu": 0.0,
                  "mem": 311422976,
                  "disk": 181846016
               }
            }
         },
         "1": {
            "state": "RUNNING",
            "isolation_segment": null,
            "stats": {
               "name": "test-app-cluster",
               "uris": [
                  "test-app-cluster.cfapps.io"
               ],
               "host": "10.10.100.121",
               "port": 61028,
               "uptime": 0,
               "mem_quota": 536870912,
               "disk_quota": 1073741824,
               "fds_quota": 16384,
               "usage": {
                  "time": "2017-07-26T08:18:54+00:00",
                  "cpu": 0.0,
                  "mem": 237670400,
                  "disk": 181846016
               }
            }
         },
         "2": {
            "state": "RUNNING",
            "isolation_segment": null,
            "stats": {
               "name": "test-app-cluster",
               "uris": [
                  "test-app-cluster.cfapps.io"
               ],
               "host": "10.10.100.122",
               "port": 61055,
               "uptime": 9,
               "mem_quota": 536870912,
               "disk_quota": 1073741824,
               "fds_quota": 16384,
               "usage": {
                  "time": "2017-07-26T08:18:54+00:00",
                  "cpu": 0.0,
                  "mem": 250224640,
                  "disk": 181846016
               }
            }
         },
         "3": {
            "state": "RUNNING",
            "isolation_segment": null,
            "stats": {
               "name": "test-app-cluster",
               "uris": [
                  "test-app-cluster.cfapps.io"
               ],
               "host": "10.10.100.123",
               "port": 61016,
               "uptime": 9,
               "mem_quota": 536870912,
               "disk_quota": 1073741824,
               "fds_quota": 16384,
               "usage": {
                  "time": "2017-07-26T08:18:54+00:00",
                  "cpu": 0.0,
                  "mem": 247504896,
                  "disk": 181846016
               }
            }
         }
      }
    """

    assert parse_nodes(response) == [
      :"app0@10.10.100.120",
      :"app1@10.10.100.121",
      :"app2@10.10.100.122",
      :"app3@10.10.100.123",
    ]
  end
end
