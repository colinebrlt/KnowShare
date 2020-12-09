require 'securerandom'

class Admin::BookingsController < ApplicationController
  include BookingsHelper
  before_action :authenticate_user!
  before_action :redirect_if_user_not_admin
  
  def index
    @bookings = Booking.all
  end 
  
  def destroy
    @booking.destroy
    respond_to do |format|
      format.html { redirect_to admin_bookings_path, notice: "La reservation a bien été annulée" }
      format.json { head :no_content }
      format.js {}
    end
  end

  private

  def booking_params
    params.require(:booking).permit(:start_date, :duration)
  end

end
