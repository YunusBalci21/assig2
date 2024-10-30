include "console.iol"
include "time.iol"

// Interface for the Calculator API operations
interface CalculatorInterface {
    RequestResponse:
        add(AddRequest)(int),
        subtract(SubtractRequest)(int)
}

// Type definitions for addition and subtraction requests
type AddRequest: void {
    x: int
    y: int
}

type SubtractRequest: void {
    x: int
    y: int
}

// Interface for monitor statistics retrieval
interface MonitorInterface {
    RequestResponse:
        getStatistics(void)(StatisticsResponse)
}

// Type definition for the statistics response
type StatisticsResponse: void {
    averageResponseTime: double
    totalCalls: int
    failureRate: double
    successRate: double
    requestRate: double
    startTime: long
    totalFailures: int
    totalSuccesses: int
}

// Test client to send requests and retrieve statistics
service TestClient {
    outputPort Calculator {
        Location: "socket://localhost:8001"
        Protocol: sodep
        Interfaces: CalculatorInterface
    }

    outputPort Monitor {
        Location: "socket://localhost:8000"
        Protocol: sodep
        Interfaces: MonitorInterface
    }

    main {
        println@Console("Starting API Monitor Test")()
        
        // Test 1: Addition operation
        println@Console("\nTest 1: Testing Addition")()
        with(addRequest) {
            .x = 5;
            .y = 3
        }
        add@Calculator(addRequest)(response)
        println@Console("5 + 3 = " + response)()

        // Test 2: Subtraction operation
        println@Console("\nTest 2: Testing Subtraction")()
        with(subRequest) {
            .x = 10;
            .y = 4
        }
        subtract@Calculator(subRequest)(response)
        println@Console("10 - 4 = " + response)()

        // Wait a bit to ensure operations are processed
        sleep@Time(1000)()

        // Test 3: Retrieve and print statistics
        println@Console("\nTest 3: Retrieving Statistics")()
        getStatistics@Monitor()(stats)
        println@Console("Statistics:")()
        println@Console("Total Calls: " + stats.totalCalls)()
        println@Console("Average Response Time: " + stats.averageResponseTime + " ms")()
        println@Console("Success Rate: " + stats.successRate + "%")()
        println@Console("Failure Rate: " + stats.failureRate + "%")()
        println@Console("Request Rate: " + stats.requestRate + " requests/sec")()

        // Test 4: Multiple addition operations in a loop
        println@Console("\nTest 4: Testing Multiple Operations")()
        for( i = 0, i < 5, i++ ) {
            with(addRequest) {
                .x = i;
                .y = i * 2
            }
            add@Calculator(addRequest)(response)
            println@Console(i + " + " + (i * 2) + " = " + response)()
        }

        // Wait again for processing
        sleep@Time(1000)()

        // Final statistics retrieval and display
        println@Console("\nFinal Statistics:")()
        getStatistics@Monitor()(stats)
        println@Console("Total Calls: " + stats.totalCalls)()
        println@Console("Average Response Time: " + stats.averageResponseTime + " ms")()
        println@Console("Success Rate: " + stats.successRate + "%")()
        println@Console("Failure Rate: " + stats.failureRate + "%")()
        println@Console("Request Rate: " + stats.requestRate + " requests/sec")()
    }
}
