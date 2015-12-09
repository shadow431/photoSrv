class SettingsController < ApplicationController

#tutorial said to add this? but app is working without it???
  def new
    @setting = Setting.new
  end

  def create
    @setting = Setting.new(setting_params)

    if @setting.save
      redirect_to @setting
    else
      render 'new'
    end
  end

  def show
    @setting = Setting.find(params[:id])
  end

  def index
    @settings = Setting.all
  end

  def edit
    @setting = Setting.find(params[:id])
  end

  def update
    @setting = Setting.find(params[:id])

    if @setting.update(setting_params)
      redirect_to @setting
    else
      render 'edit'
    end
  end
  def destroy
    @setting = Setting.find(params[:id])
    @setting.destroy

    redirect_to settings_path
  end

  private
    def setting_params
      params.require(:setting).permit(:name,:value)
    end

end
