class CrowdAuthSourcesController < AuthSourcesController

  unloadable

  protected
  
  def auth_source_class
    AuthSourceCrowd
  end
end
