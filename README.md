🏨 Hotel Room Booking System (SAP ABAP Cloud – RAP)

A Hotel Room Booking System developed using the RESTful ABAP Programming Model (RAP) on SAP BTP ABAP Environment, integrated with SAP Fiori Elements UI.
This project showcases an end-to-end transactional system for managing hotel rooms and bookings with draft handling, unmanaged save logic, and dynamic UI behavior.

🌟 KEY FEATURES
🔹 Draft Handling
Enables users to create and edit records safely
Changes are saved only after final confirmation
Ensures data consistency and reliability

🔹 1:N Data Model (Header–Item Relationship)
Header: Hotel Room
Item: Bookings linked to each room

🔹 Dynamic Value Help (Dropdowns)
Implemented using ABAP Domains + CDS Value Help Views
Examples:
      Room Type
      Floor Number
      Capacity

🔹 UI Side Effects (Real-Time Updates)
Automatically updates Price Per Night when Room Type is selected
Room Type	Price
SINGLE	1000
DOUBLE	2000

✅ No page refresh required

🔹 Automated Booking Calculation
Calculates Total Amount dynamically Based on:
     Check-in Date
     Check-out Date
     Price per Night


🔹 Unmanaged Save Logic
Custom implementation using utility class:
👉 ZCL_HOTEL_UTL
Handles:
       Transactional buffer
       Manual database operations during RAP save sequence
🏗️ TECHNICAL ARCHITECTURE:

🔹 1. Database Layer
ZCIT_ROOM_T → Stores Room details
ZCIT_BOOK_T → Stores Booking details

Draft Tables (Auto-generated):
ZCIT_ROOM_D
ZCIT_BOOK_D

🔹 2. CDS DATA MODEL
✅ Interface Views (Core Layer)
ZCIT_ROOM_010 → Root Entity
ZCIT_BOOK_010 → Child Entity
✅ Projection Views (Consumption Layer)
ZCIT_ROOM_020
ZCIT_BOOK_020
✅ Value Help Views
Uses: DDCDS_CUSTOMER_DOMAIN_VALUE_T
Provides dropdown values from ABAP Domains

🔹 3. BEHAVIOR DEFINITION & IMPLEMENTATION
✅ Type
Unmanaged with Draft

unmanaged implementation in class ...
with draft;
✅ Handler Classes
📌 LHC_ROOM
Validations
Authorizations
Price Determination
📌 LHC_BOOKING
Total Amount Calculation
Default Status Determination
Custom Action → Mark as Paid
✅ Saver Class
📌 LSC_ZCIT_ROOM_010

Handles:
      Transaction Buffer
      Manual MODIFY and DELETE operations


🔹 4. UI LAYER (SAP FIORI ELEMENTS)
✅ Metadata Extensions (MDE)
Defines UI structure:
Facets
Line Items
Identification Sections
Action Buttons

✅ OData Services
Service Definition → ZCIT_ROOM_SRV
Service Binding → OData V2 / V4

💡 TECHNICAL HIGHLIGHTS
🔹 RAP Side Effects
     side effects { field RoomType affects field PricePerNight; }
    ✅ Ensures real-time UI update when Room Type changes

🔹 CDS Value Help (Dropdown)
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_ROOMTYPE_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T(
    p_domain_name: 'ZDO_ROOMTYPE'
  )

✅ Forces Fiori UI to render a dropdown

🚀 HOW TO RUN THE PROJECT
    🔧 Steps:
             Clone the repository using abapGit
             Activate objects in sequence:
             Domains & Data Elements
             Tables
             CDS Views
             Behavior Definitions & Classes
             Publish Service Binding
             ZCIT_ROOM_UI_V4
             Click Preview to launch the Fiori application

👨‍💻 Author
Anish Kumar T

SAP ABAP Cloud Developer
GitHub: https://github.com/Anishkumar0007
LinkedIn: www.linkedin.com/in/anish-kumar-t-419b3729b

📸 App Preview:

<img width="1897" height="882" alt="image" src="https://github.com/user-attachments/assets/757f1045-8e32-4bed-ab24-f8fbef95d0df" />


