include "time.iol"
include "console.iol"

interface CalculatorInterface {
    RequestResponse:
        add(AddRequest)(int) throws ServiceNotAvailable,
        subtract(SubtractRequest)(int) throws ServiceNotAvailable
}

type AddRequest:void {
    x: int
    y: int
}

type SubtractRequest:void {
    x: int
    y: int
}

interface MonitorInterface {
    RequestResponse:
        getStatistics(void)(StatisticsResponse)
}

type StatisticsResponse:void {
    .averageResponseTime: double
    .totalCalls: int
    .failureRate: double
    .successRate: double
    .requestRate: double
    .startTime: long
    .totalFailures: int
    .totalSuccesses: int
}

service APIMonitor {
    execution: concurrent

    inputPort Monitor {
        Location: "socket://localhost:8000"
        Protocol: sodep
        Interfaces: MonitorInterface
    }

    inputPort Calculator {
        Location: "socket://localhost:8001"
        Protocol: sodep
        Interfaces: CalculatorInterface
    }

    outputPort TargetServicePort {
        Location: "socket://localhost:8002"
        Protocol: sodep
        Interfaces: CalculatorInterface
    }

    init {
        with (global) {
            .totalResponseTime = 0.0
            .totalCalls = 0
            .totalFailures = 0
            .totalSuccesses = 0
            getCurrentTimeMillis@Time()(.startTime)
            println@Console("Monitor started - listening on ports 8000 and 8001")()
        }
    }

    define updateStats {
        synchronized( statsLock ) {
            global.totalResponseTime += responseTime
            global.totalCalls++

            if (hasError) {
                global.totalFailures++
            } else {
                global.totalSuccesses++
            }

            getCurrentTimeMillis@Time()(currentTime)
            if (global.totalCalls > 0) {
                global.requestRate = (global.totalCalls * 1000.0) / (currentTime - global.startTime)
                global.failureRate = (global.totalFailures * 100.0) / global.totalCalls
                global.successRate = (global.totalSuccesses * 100.0) / global.totalCalls
            }
        }
    }

    main {
        [ add(request)(response) {
            getCurrentTimeMillis@Time()(startTime)
            hasError = false

            scope(addScope) {
                install(default => {
                    hasError = true;
                    getCurrentTimeMillis@Time()(endTime);
                    responseTime = endTime - startTime;
                    updateStats;
                    throw(ServiceNotAvailable)
                })
                
                add@TargetServicePort(request)(response);
                getCurrentTimeMillis@Time()(endTime);
                responseTime = endTime - startTime;
                updateStats
            }
        } ]

        [ subtract(request)(response) {
            getCurrentTimeMillis@Time()(startTime)
            hasError = false

            scope(subtractScope) {
                install(default => {
                    hasError = true;
                    getCurrentTimeMillis@Time()(endTime);
                    responseTime = endTime - startTime;
                    updateStats;
                    throw(ServiceNotAvailable)
                })
                
                subtract@TargetServicePort(request)(response);
                getCurrentTimeMillis@Time()(endTime);
                responseTime = endTime - startTime;
                updateStats
            }
        } ]

        [ getStatistics()(response) {
            synchronized( statsLock ) {
                if (global.totalCalls > 0) {
                    response.averageResponseTime = global.totalResponseTime / global.totalCalls
                } else {
                    response.averageResponseTime = 0.0
                }
                response.totalCalls = global.totalCalls
                response.failureRate = global.failureRate
                response.successRate = global.successRate
                response.requestRate = global.requestRate
                response.startTime = global.startTime
                response.totalFailures = global.totalFailures
                response.totalSuccesses = global.totalSuccesses
            }
        } ]
    }
}