Rails.application.routes.draw do
  get("/", { :controller => "movies", :action => "index" })

  # Routes for the Movie resource:

  # CREATE
  post("/movies", { :controller => "movies", :action => "create" })
  get("/movies/new", { :controller => "movies", :action => "new" })
          
  # READ
  get("/movies", { :controller => "movies", :action => "index" })
  get("/movies/:id", { :controller => "movies", :action => "show" })
  
  # UPDATE
  patch("/movies/:id", { :controller => "movies", :action => "update" })
  get("/movies/:id/edit", { :controller => "movies", :action => "edit" })
  
  # DELETE
  delete("/movies/:id", { :controller => "movies", :action => "destroy" })

  #------------------------------
end