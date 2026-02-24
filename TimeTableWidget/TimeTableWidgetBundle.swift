//
//  TimeTableWidgetBundle.swift
//  TimeTableWidget
//
//  Created by Federico Musso on 24/02/26.
//

import WidgetKit
import SwiftUI

@main
struct TimeTableWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextClassWidget()
        TodayScheduleWidget()
        TimeTableWidgetControl()
    }
}
