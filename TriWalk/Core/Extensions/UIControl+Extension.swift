//
//  UIControl+Extension.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit
import Combine

extension UIControl {
    func controlPublisher(for event: UIControl.Event) -> EventPublisher {
        EventPublisher(control: self, event: event)
    }
}

struct EventPublisher: Publisher {
    typealias Output = UIControl
    typealias Failure = Never
    
    let control: UIControl
    let event: UIControl.Event
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = EventSubscription(control: control, subscriber: subscriber, event: event)
        subscriber.receive(subscription: subscription)
    }
}

fileprivate class EventSubscription<EventSubscriber: Subscriber>: Subscription
    where EventSubscriber.Input == UIControl, EventSubscriber.Failure == Never {
    
    let control: UIControl
    let event: UIControl.Event
    var subscriber: EventSubscriber?
    
    init(control: UIControl, subscriber: EventSubscriber, event: UIControl.Event) {
        self.control = control
        self.subscriber = subscriber
        self.event = event
        control.addTarget(self, action: #selector(eventDidOccur), for: event)
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        DispatchQueue.main.async {
            self.subscriber = nil
            self.control.removeTarget(self, action: #selector(self.eventDidOccur), for: self.event)
        }
    }
    
    @objc func eventDidOccur() {
        DispatchQueue.main.async {
            _ = self.subscriber?.receive(self.control)
        }
    }
}
