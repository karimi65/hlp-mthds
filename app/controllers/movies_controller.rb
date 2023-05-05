class MoviesController < ApplicationController
  def new
    @the_movie = Movie.new

    render template: "movies/new.html.erb"
  end

  def index
    matching_movies = Movie.all

    @list_of_movies = matching_movies.order({ :created_at => :desc })

    respond_to do |format|
      format.json do
        render json: @list_of_movies
      end

      format.html do
        render({ :template => "movies/index.html.erb" })
      end
    end
  end

  def show
    the_id = params.fetch(:id)

    matching_movies = Movie.where({ :id => the_id })

    @the_movie = matching_movies.first

    render({ :template => "movies/show.html.erb" })
  end

  def create
    @the_movie = Movie.new
    @the_movie.title = params.fetch("query_title")
    @the_movie.description = params.fetch("query_description")

    if @the_movie.valid?
      @the_movie.save
      redirect_to("/movies", { :notice => "Movie created successfully." })
    else
      render template: "movies/new.html.erb"
    end
  end

  def edit
    the_id = params.fetch(:id)

    matching_movies = Movie.where({ :id => the_id })

    @the_movie = matching_movies.first

    render({ :template => "movies/edit.html.erb" })
  end

  def update
    the_id = params.fetch(:id)
    the_movie = Movie.where({ :id => the_id }).first

    the_movie.title = params.fetch("query_title")
    the_movie.description = params.fetch("query_description")

    if the_movie.valid?
      the_movie.save
      redirect_to("/movies/#{the_movie.id}", { :notice => "Movie updated successfully."} )
    else
      redirect_to("/movies/#{the_movie.id}", { :alert => "Movie failed to update successfully." })
    end
  end

  def destroy
    the_id = params.fetch(:id)
    the_movie = Movie.where({ :id => the_id }).first

    the_movie.destroy

    redirect_to("/movies", { :notice => "Movie deleted successfully."} )
  end
end
