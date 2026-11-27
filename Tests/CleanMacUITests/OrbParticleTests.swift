@testable import CleanMacUI
import Foundation
import Testing

struct OrbParticleTests {
    /// A moment when the first particle sets off on a trip.
    private let tripStart: TimeInterval = 0

    /// Moments spread over one trip of the first particle, from its start to just before its end.
    private var momentsOfOneTrip: [TimeInterval] {
        (0..<20).map { tripStart + OrbParticle.lifetime * Double($0) / 20 }
    }

    @Test func aParticleIsAlwaysPartWayThroughATrip() {
        for index in 0..<OrbParticle.count {
            for time in stride(from: 0.0, through: 30, by: 0.37) {
                let progress = OrbParticle(index: index).position(at: time).progress
                #expect(progress >= 0 && progress < 1)
            }
        }
    }

    /// The orb draws with the time since 2001, which is in the hundreds of millions of seconds.
    @Test func aParticleKeepsMovingSmoothlyAtTheTimesTheOrbDrawsWith() {
        let now = Date(timeIntervalSinceReferenceDate: 815_000_000).timeIntervalSinceReferenceDate
        let particle = OrbParticle(index: 5)
        let before = particle.position(at: now)
        let after = particle.position(at: now + 0.1)
        // Counted across the start of a new trip as well.
        let step = (after.progress - before.progress + 1).truncatingRemainder(dividingBy: 1)

        #expect(before.progress >= 0 && before.progress < 1)
        #expect(abs(step - 0.1 / OrbParticle.lifetime) < 1e-6)
    }

    @Test func particlesSetOffOneAfterTheOther() {
        let progresses = (0..<OrbParticle.count).map { OrbParticle(index: $0).position(at: tripStart).progress }

        #expect(Set(progresses).count == OrbParticle.count)
        #expect(progresses.first == 0)
    }

    @Test func particlesSetOffFromDifferentAngles() {
        let angles = (0..<OrbParticle.count).map { index in
            OrbParticle(index: index).position(at: tripStart).angle.truncatingRemainder(dividingBy: 2 * .pi)
        }

        #expect(Set(angles).count == OrbParticle.count)
    }

    @Test func aParticleGetsCloserToTheRingAllTheWay() {
        let distances = momentsOfOneTrip.map { OrbParticle(index: 0).position(at: $0).distance }

        #expect(distances.first == 1)
        #expect(zip(distances, distances.dropFirst()).allSatisfy { earlier, later in later < earlier })
        #expect(distances.allSatisfy { distance in distance > 0 && distance <= 1 })
    }

    @Test func aParticleFadesInAsItSetsOffAndOutAsItArrives() {
        let particle = OrbParticle(index: 0)
        let start = particle.position(at: tripStart)
        let middle = particle.position(at: tripStart + OrbParticle.lifetime / 2)
        let nearEnd = particle.position(at: tripStart + OrbParticle.lifetime * 0.99)

        #expect(start.opacity == 0)
        #expect(middle.opacity == 1)
        #expect(nearEnd.opacity < 0.1)
    }

    @Test func aParticleShrinksOnItsWayIn() {
        let particle = OrbParticle(index: 0)

        #expect(particle.position(at: tripStart).scale == 1)
        #expect(particle.position(at: tripStart + OrbParticle.lifetime * 0.9).scale < 0.6)
    }

    @Test func eachTripStartsFromAnotherAngle() {
        let particle = OrbParticle(index: 3)
        let firstTrip = particle.position(at: tripStart)
        let nextTrip = particle.position(at: tripStart + OrbParticle.lifetime)

        #expect(abs(firstTrip.progress - nextTrip.progress) < 1e-6)
        #expect(abs(firstTrip.angle - nextTrip.angle) > 0.1)
    }
}
