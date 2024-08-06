#include "VRPNController.h"
#include <sstream>

using namespace godot;

void VRPN_CALLBACK handle_dtrack_tracker(void *userData, const vrpn_TRACKERCB data) {
    if (userData == nullptr)
        return;
    VRPNController::TrackerData trackerData;
    trackerData.Pos[0] = data.pos[0];
    trackerData.Pos[1] = data.pos[1];
    trackerData.Pos[2] = data.pos[2];
    trackerData.Quat[0] = data.quat[0];
    trackerData.Quat[1] = data.quat[1];
    trackerData.Quat[2] = data.quat[2];
    trackerData.Quat[3] = data.quat[3];

    auto *thisptr = (VRPNController *)userData;

    // store recent data
    thisptr->TrackerDataMap.emplace(data.sensor, trackerData);

    thisptr->tracker_changed(data.sensor, Vector3(data.pos[0], data.pos[1], data.pos[2]),
               Quaternion(data.quat[0], data.quat[1], data.quat[2], data.quat[3]));
}

void VRPN_CALLBACK handle_dtrack_analog(void *userData, const vrpn_ANALOGCB data)
{
    if (userData == nullptr)
        return;

    auto *thisptr = (VRPNController *)userData;

    // store recent data
    Array   channels;
    thisptr->AnalogDataField.NumChannels = data.num_channel;

    for (int i = 0; i < thisptr->AnalogDataField.NumChannels; ++i)
    {
        thisptr->AnalogDataField.Channel[i] = data.channel[i];
        channels.push_back(data.channel[i]);
    }

    thisptr->analog_changed(data.num_channel, channels);
}

void VRPN_CALLBACK handle_dtrack_button(void *userData, const vrpn_BUTTONCB data)
{
    if (userData == nullptr)
        return;

    auto *thisptr = (VRPNController *)userData;

    // store recent data
    thisptr->ButtonDataMap.emplace(data.button, data.state == 1 ? ButtonState::Pressed : ButtonState::Released);

    thisptr->button_pressed(data.button, data.state == 1);
}

VRPNController::VRPNController() {

}

VRPNController::~VRPNController() {
   //this->connection.reset();
   this->tracker.reset();
   this->analog.reset();
   this->button.reset();
}

void VRPNController::_bind_methods() {
   ClassDB::bind_method(D_METHOD("init", "device", "hostIP", "port"), &VRPNController::init);
   ClassDB::bind_method(D_METHOD("poll"), &VRPNController::poll);

   ADD_SIGNAL(MethodInfo("tracker_changed", PropertyInfo(Variant::INT, "sensor"), PropertyInfo(Variant::VECTOR3, "tracker_pos"),
               PropertyInfo(Variant::QUATERNION, "tracker_quat")));
   ADD_SIGNAL(MethodInfo("analog_changed", PropertyInfo(Variant::INT, "num_channels"), PropertyInfo(Variant::ARRAY, "channels")));
   ADD_SIGNAL(MethodInfo("button_pressed", PropertyInfo(Variant::INT, "button"), PropertyInfo(Variant::BOOL, "pressed")));
}

void VRPNController::_process(float delta) {

}

void VRPNController::init(const godot::String& device, const godot::String& hostIP, uint32_t port) {
   // Connect to VRPN
   std::stringstream nic;
   nic << device.utf8().get_data() << "@" << hostIP.utf8().get_data() << ":" << port;
   std::cout << nic.str() << std::endl;
   connection  = std::shared_ptr<vrpn_Connection>(vrpn_get_connection_by_name(nic.str().c_str()));

   // Check state
   std::string msg = "VRPNController: connecting "+nic.str();
   if( connection->connected() ) msg += " done!";
   else msg += " failed!";
   std::cout << msg << std::endl;

   // create the tracker (marker + flystick) component and register the handler
   this->tracker = std::make_shared<vrpn_Tracker_Remote>(device.utf8().get_data(), connection.get());
   this->tracker->register_change_handler(this, handle_dtrack_tracker);

   // create the flystick analog stick
   this->analog = std::make_shared<vrpn_Analog_Remote>(device.utf8().get_data(), connection.get());
   this->analog->register_change_handler(this, handle_dtrack_analog);

   // create the flystick buttons
   this->button = std::make_shared<vrpn_Button_Remote>(device.utf8().get_data(), connection.get());
   this->button->register_change_handler(this, handle_dtrack_button);
}

void VRPNController::poll() {
   if (tracker)
      tracker->mainloop();

   if (analog)
      analog->mainloop();

   if (button)
      button->mainloop();

   if (connection)
      connection->mainloop();

   // this blocks rendering :(
   //vrpn_SleepMsecs(20);
}

void VRPNController::tracker_changed(int sensor, const Vector3 &pos, const Quaternion &quat) {
   emit_signal("tracker_changed", sensor, pos, quat);
}

void VRPNController::analog_changed(int num_channels, const Array &channels) {
   emit_signal("analog_changed", num_channels, channels);
}

void VRPNController::button_pressed(int button, bool pressed) {
   emit_signal("button_pressed", button, pressed);
}
