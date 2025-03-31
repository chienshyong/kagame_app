//List of events used to communicate between pages

import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

//Listeners: WardrobePage and CategoryPage
//Triggers: Add clothes, Delete clothes
class WardrobeRefreshEvent {}