model shortest_path_with_weight

global {
  graph my_graph;
  list<point> nodes;
  list<float> time_list; // list of time to arrive to next node;
  geometry shape <- square(150 #m);

  init {
    add point(10, 10) to: nodes;
    add point(10, 90) to: nodes;
    add point(40, 20) to: nodes;
    add point(80, 50) to: nodes;
    add point(90, 20) to: nodes;
    add point(50, 90) to: nodes;
    add point(30, 20) to: nodes;
    add point(110, 50) to: nodes;
    add point(120, 20) to: nodes;
    add point(50, 120) to: nodes;
    add point(100, 110) to: nodes;
    loop i from: 0 to: length(nodes) - 1 {
      create my_node {
        location <- nodes[i];
      }

    }

    create road {
      shape <- line([my_node[0], my_node[1]]);
      link_length <- shape.perimeter * 2; // double link length test
      free_speed <- 5 #m / #s;
      max_capacity <- 10;
    }

    create road {
      shape <- line([my_node[1], my_node[2]]);
      link_length <- shape.perimeter;
      free_speed <- 5 #m / #s;
      max_capacity <- 10;
    }

    create road {
      shape <- line([my_node[2], my_node[3]]);
      link_length <- shape.perimeter;
      free_speed <- 5 #m / #s;
      max_capacity <- 10;
    }

    create road {
      shape <- line([my_node[3], my_node[4]]);
      link_length <- shape.perimeter;
      free_speed <- 5 #m / #s;
      max_capacity <- 10;
    }

    create road {
      shape <- line([my_node[4], my_node[5]]);
      link_length <- shape.perimeter;
      free_speed <- 5 #m / #s;
      max_capacity <- 10;
    }

    create road {
      shape <- line([my_node[5], my_node[6]]);
      link_length <- shape.perimeter;
      free_speed <- 5 #m / #s;
      max_capacity <- 10;
    }

    my_graph <- as_edge_graph(road) with_weights (road as_map (each::each.link_length));
    //    do create_people(30);

    // TEST people
    create people number: 8 {
      location <- nodes[0];
      dest <- nodes[4];
      shortest_path <- path_between(my_graph, location, dest);
      fixed_vertices <- shortest_path.vertices;
      num_nodes_to_complete <- length(shortest_path.vertices) - 1;

      // ONLY NEED TIME
      //      speed <- (5 + rnd(0.0, 5.0)) #m / #s;
    }

    // change to 6-2 to REVERT TOBEGINNING
    create people number: 3 {
      location <- nodes[0];
      dest <- nodes[4];
      shortest_path <- path_between(my_graph, location, dest);
      fixed_vertices <- shortest_path.vertices;
      num_nodes_to_complete <- length(shortest_path.vertices) - 1;
      //      speed <- (5 + rnd(0.0, 5.0)) #m / #s;
    }

    //    write shortest_path.segments[0];
    //    write road[0].shape;
    //    write shortest_path.segments[0] = road[0].shape;
    //    float total;
    //    loop x over: shortest_path.segments {
    //      total <- total + x.perimeter;
    //    }
    //
    //    write "______________";
    //    write total;
    //    write nodes[0] distance_to nodes[1];
    //    write shortest_path.vertices;
    //    write shortest_path.segments;
  }

  // empty list first then update min time
  reflex refresh_min_time {
    time_list <- [];
    do update_min_time;
  }

  action create_people (int num_people) {
    create people number: num_people {
      int random_origin_index <- rnd(length(nodes) - 1);
      location <- nodes[random_origin_index];
      int random_dest_index <- rnd(length(nodes) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(nodes) - 1);
      }

      dest <- nodes[random_dest_index];
      shortest_path <- path_between(my_graph, location, dest);
      fixed_vertices <- shortest_path.vertices;
      num_nodes_to_complete <- length(shortest_path.vertices) - 1;
      speed <- (5 + rnd(0.0, 5.0)) #m / #s;
    }

  }

  action update_min_time {
    ask people {
      point next_node <- point(fixed_vertices[next_node_index]);
      // list of road (polylines) segments on shortest path
      list<road> path_roads <- shortest_path.edges collect (road(each));
      //      write path_roads collect (each.link_length with_precision 2); // debug distance      
      current_road <- path_roads[next_node_index - 1]; // current road segment
      float true_link_length <- current_road.link_length; // link length (real_)
      write "True link length: " + true_link_length;
      float distance_to_next_node <- self distance_to next_node; // gama distance (2d graph)
      write "GAMA distance: " + distance_to_next_node;
      is_road_jammed <- current_road.current_volume = current_road.max_capacity; // is person stuck?
//      write string(current_road.current_volume) + "/" + current_road.max_capacity;
//      write "JAMMED STATUS: " + is_road_jammed;
      
      if (is_road_jammed = false) { // only do stuff is road is not jammed
      // FIND initial RATIO + speed at start of each road
        if (is_on_node = true) {
          write "IS ON NODE";
          ratio <- true_link_length / distance_to_next_node;
          speed <- myself.get_equi_speed(current_road.free_speed, current_road.current_volume, current_road.max_capacity);
          is_on_node <- false;
          current_road.current_volume <- current_road.current_volume + 1; // increase traffic volume of the road
        }

        write "RATIO: " + ratio;
        real_dist_to_next_node <- distance_to_next_node * ratio;        
        float travel_time <- real_dist_to_next_node / speed;
        //      write "REAL travel_time: " + travel_time;
        add travel_time to: time_list;
      }

    }

    float min_time <- min(time_list);
    //    write "MIN_TIME: " + min_time;
    ask people {
      step <- min_time;
    }
    write min_time;

  }

  // BPR equation
  float get_equi_speed (float free_speed, int current_volume, int max_capacity) {
    return free_speed / (1 + 0.15 * (current_volume / max_capacity) ^ 4);
  }

  action mouse_down_evt {
    geometry circ <- circle(1, #user_location);
    list<people> test <- people inside circ;
    if (length(test) > 0) {
      people selected_person <- test[0];
      write selected_person;
      ask selected_person {
        if (clicked = true) {
          clicked <- false;
        } else {
          clicked <- true;
        }

      }

    }

  }

  // TEST epsilon value
  bool test_epsilon <- false;

  reflex stop when: length(people) = 0 {
    write "HALT";
    do pause;
  }

  // TEST
  int node_counter <- 0;
}

species people skills: [moving] {
  rgb color <- rgb([rnd(255), rnd(255), rnd(255)]);
  point dest; // destination node
  path shortest_path; // shortest path
  list<point> fixed_vertices;
  int num_nodes_to_complete;
  int next_node_index <- 1;
  bool is_on_node <- true;
  bool clicked <- false; // gui variable
  float ratio <- 1.0;
  float real_dist_to_next_node;
  road current_road;
  bool is_road_jammed <- false;
  
  // Smart move
  reflex smart_move when: is_road_jammed = false {
//    write "pre-speed: " + speed;
    point next_node <- point(fixed_vertices[next_node_index]);
    float epsilon <- 10 ^ -5;
    //    write "DIST:" + distance_to_next_node;
    // change step so that person stops at node before going into new road
    //    write "Step time: " + step + "s";
    // MOVE
    do follow path: shortest_path;
    //    write "TRAVELLED: " + (self distance_to fixed_vertices[next_node_index - 1]) * ratio;
    if (real_dist_to_next_node < epsilon) {
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      write "EPSILON--------------------------------";
      self.location <- next_node.location;
      test_epsilon <- true;
    }

    write "---------------------";

    // CHECK IF PERSON IS ON ONE NODE
    if (self overlaps next_node) {
//      write "OVERLAPS";
      current_road.current_volume <- current_road.current_volume - 1;
      //      write "OVERLAPS";
      // if its the final node
      if (next_node_index = num_nodes_to_complete) {
      //        write "ARRIVED!";
        do die;
      } else {
        is_on_node <- true;
        next_node_index <- next_node_index + 1;
      }

    }

    //    do follow path: shortest_path;
    //    step <- (self distance_to point(shortest_path.vertices[1])) / speed;
    //    write step;
    //    write self overlaps point(shortest_path.vertices[1]); // check if people is ON the node
    //    write agents_inside(shortest_path.vertices[1]);
    //    write (self distance_to point(shortest_path.vertices[1]));
    //    do goto target: nodes[1] on: my_graph;
    //    write (self distance_to point(shortest_path.vertices[1]));

  }

  aspect base {
    if (clicked = true) {
      path new_path <- path_between(my_graph, location, dest);
      draw circle(2) at: point(new_path.source) color: #yellow;
      draw circle(2) at: point(new_path.target) color: #cyan;
      draw new_path.shape color: #magenta width: 5;
    }

    draw circle(1.5) color: color;
  }

}

species my_node {
  int node_number;

  init {
    node_number <- node_counter;
    node_counter <- node_counter + 1;
  }

  aspect base {
  //    draw circle(1) color: #lightblue;
    draw string(node_number) color: #gray font: font('Helvetica', 15, #plain);
  }

}

species road {
  float link_length;
  float free_speed;
  int max_capacity;
  int current_volume <- 0 min: 0 max: max_capacity;
  float link_full_percentage -> {current_volume / max_capacity};
  rgb color;

  aspect base {
    if (link_full_percentage <= 0.25) {
      color <- #lime;
    } else if (link_full_percentage <= 0.5) {
      color <- #yellow;
    } else if (link_full_percentage <= 0.75) {
      color <- #orange;
    } else {
      color <- #red;
    }
    draw shape color: color width: 2;    
    draw string(self.shape.perimeter with_precision 2) color: #black font: font('Helvetica', 10, #plain);
  }

}

experiment my_experiment type: gui {
  output {
    display my_display type: opengl background: #white {
      species road aspect: base;
      species people aspect: base;
      species my_node aspect: base;
      //      graphics "nodes" {
      //        loop n over: my_graph.vertices {
      //          draw circle(2) at: point(n) color: #purple;
      //        }
      //
      //      }
      event [mouse_down] action: mouse_down_evt;
    }

  }

}